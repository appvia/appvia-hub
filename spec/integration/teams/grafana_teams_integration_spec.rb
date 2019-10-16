require 'rails_helper'

RSpec.describe 'Grafana teams end-to-end' do
  include_context 'time helpers'

  let(:agent_class) { GrafanaAgent }

  let!(:user) { create :user }
  let!(:other_user) { create :user }

  def reload_all(*args)
    user.reload
    other_user.reload

    args.each(&:reload)
  end

  def process_jobs
    move_time_to 1.minute.from_now
    Sidekiq::Worker.drain_all
  end

  context 'with no integrations yet' do
    before do
      expect(agent_class).to receive(:new).never
    end

    it 'doesn\'t synchronise grafana users' do
      team1, success = TeamsService.create(
        {
          name: 'Team 1',
          slug: 'team-1',
          description: 'This is Team numero uno'
        },
        user
      )
      expect(success).to be true
      expect(team1.slug).to eq 'team-1'

      # `user` should've been made an admin of the team automatically.
      expect(TeamMembershipsService.user_an_admin_of_team?(team1.id, user)).to be true
      expect(TeamMembership.exists?(team: team1, user: user, role: 'admin')).to be true

      expect(Sidekiq::Worker.jobs.size).to eq 2

      expect_any_instance_of(agent_class).to receive(:sync_team).never

      process_jobs

      reload_all team1

      TeamsService.destroy! team1

      expect(Sidekiq::Worker.jobs.size).to eq 1

      expect_any_instance_of(agent_class).to receive(:sync_team).never

      process_jobs
    end
  end

  context 'with integrations' do
    let :integration_config do
      {
        'url' => 'http://my-grafana.com',
        'api_key' => 'secret api key thing',
        'ca_cert' => 'some certificate',
        'template_url' => 'https://s3.amazonaws.com/some-template.json',
        'admin_username' => 'mrs admin',
        'admin_password' => 'very secret password'
      }
    end

    let :agent_initializer_params do
      integration_config.symbolize_keys.except(
        :agent_base_url,
        :agent_token,
        :url,
        :api_key,
        :ca_cert,
        :admin_username,
        :admin_password
      )
    end
    let(:agent) { instance_double(agent_class) }

    before do
      expect(agent_class).to receive(:new)
        .with(**agent_initializer_params)
        .and_return(agent)
        .at_least(:once)
    end

    it 'syncs users up to grafana' do
      # Start by creating an integration, without any allocations, so open to all
      # teams.

      expect(Integration.count).to be 0

      integration, success = Admin::IntegrationsService.create(
        name: 'Integration 1',
        provider_id: 'grafana',
        config: integration_config
      )

      expect(success).to be true
      expect(Integration.count).to be 1
      expect(integration.grafana?).to be true

      expect(Sidekiq::Worker.jobs.size).to eq 1

      process_jobs

      # Create a team and check that it syncs users to Grafana.

      reload_all integration

      team1, success = TeamsService.create(
        {
          name: 'Team 1',
          slug: 'team-1',
          description: 'This is Team numero uno'
        },
        user
      )
      expect(success).to be true
      expect(team1.slug).to eq 'team-1'

      # `user` should've been made an admin of the team automatically.
      expect(TeamMembershipsService.user_an_admin_of_team?(team1.id, user)).to be true
      expect(TeamMembership.exists?(team: team1, user: user, role: 'admin')).to be true

      expect(Sidekiq::Worker.jobs.size).to eq 2

      expect(agent).to receive(:sync_team)
        .with(team.memberships)

      process_jobs
    end
  end
end
