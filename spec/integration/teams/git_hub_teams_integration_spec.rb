require 'rails_helper'

RSpec.describe 'GitHub teams end-to-end' do
  include_context 'time helpers'

  let(:agent_class) { GitHubAgent }

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

    it 'doesn\'t perform any synchronisation of teams' do
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

      expect_any_instance_of(agent_class).to receive(:create_team).never
      expect_any_instance_of(agent_class).to receive(:add_user_to_team).never

      process_jobs

      reload_all team1

      TeamsService.destroy! team1

      expect(Sidekiq::Worker.jobs.size).to eq 1

      expect_any_instance_of(agent_class).to receive(:delete_team).never
      expect_any_instance_of(agent_class).to receive(:remove_user_from_team).never

      process_jobs
    end
  end

  context 'with integrations' do
    let :integration_config do
      {
        'org' => 'org_foo',
        'app_id' => 12_345,
        'app_private_key' => 'foo_private_key',
        'app_installation_id' => 1_010_101,
        'app_client_id' => 'app client id',
        'app_client_secret' => 'supersecret',
        'enforce_best_practices' => true
      }
    end

    let :agent_initializer_params do
      integration_config.symbolize_keys.except(
        :enforce_best_practices,
        :app_client_id,
        :app_client_secret
      )
    end
    let(:agent) { instance_double(agent_class) }

    before do
      expect(agent_class).to receive(:new)
        .with(**agent_initializer_params)
        .and_return(agent)
        .at_least(:once)
    end

    it 'handles the synchronisation of teams and team members accordingly' do
      # Start by creating an integration, without any allocations, so open to all
      # teams.

      expect(Integration.count).to be 0

      integration, success = Admin::IntegrationsService.create(
        name: 'Integration 1',
        provider_id: 'git_hub',
        config: integration_config
      )

      expect(success).to be true
      expect(Integration.count).to be 1
      expect(integration.git_hub?).to be true

      expect(Sidekiq::Worker.jobs.size).to eq 1

      process_jobs

      # Create a team and check that it gets syned up with GitHub.

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

      expect(agent).to receive(:create_team)
        .with('hub-team-1', team1.description)

      process_jobs

      # Now connect up `user`'s GitHub identity to actually make them a team
      # member on GitHub.

      reload_all integration, team1

      IdentitiesService.create!(
        integration.user_identities,
        user: user,
        external_id: 123,
        external_username: 'foo',
        external_name: 'Foo',
        external_email: 'foo@example.com',
        access_token: 'this is a very very long token, I think'
      )

      expect(Sidekiq::Worker.jobs.size).to eq 1

      expect(agent).to receive(:add_user_to_team)
        .with('hub-team-1', 'foo')

      process_jobs

      # Now add `other_user` to Team 1, then connect up their identity, and check
      # that they get added to the GitHub team too.

      reload_all integration, team1

      TeamMembershipsService.create_or_update!(
        team: team1,
        user_id: other_user.id,
        role: nil
      )

      expect(Sidekiq::Worker.jobs.size).to eq 1

      process_jobs

      IdentitiesService.create!(
        integration.user_identities,
        user: other_user,
        external_id: 234,
        external_username: 'bar',
        external_name: 'Bar',
        external_email: 'bar@example.com',
        access_token: 'this is another very very long token, I think'
      )

      expect(Sidekiq::Worker.jobs.size).to eq 1

      expect(agent).to receive(:add_user_to_team)
        .with('hub-team-1', 'bar')

      process_jobs

      # Now create a second team with the other user as admin - this time they
      # should straight away be added to the GitHub team as they already have an
      # identity connected.

      reload_all integration, team1

      team2, success = TeamsService.create(
        {
          name: 'Team 2',
          slug: 'team-2',
          description: 'This is Team numero dos'
        },
        other_user
      )
      expect(success).to be true
      expect(team2.slug).to eq 'team-2'

      # `other_user` should've been made an admin of the team automatically.
      expect(TeamMembershipsService.user_an_admin_of_team?(team2.id, other_user)).to be true
      expect(TeamMembership.exists?(team: team2, user: other_user, role: 'admin')).to be true

      expect(Sidekiq::Worker.jobs.size).to eq 2

      expect(agent).to receive(:create_team)
        .with('hub-team-2', team2.description)

      expect(agent).to receive(:add_user_to_team)
        .with('hub-team-2', 'bar')
        .twice

      process_jobs

      # Now remove `other_user` from Team 1 and check that they are removed from the
      # GitHub team too.

      reload_all integration, team1, team2

      TeamMembershipsService.destroy!(
        team: team1,
        user_id: other_user.id
      )

      expect(TeamMembershipsService.user_a_member_of_team?(team1.id, other_user)).to be false
      expect(TeamMembership.exists?(team: team1, user: other_user)).to be false

      expect(Sidekiq::Worker.jobs.size).to eq 1

      expect(agent).to receive(:remove_user_from_team)
        .with('hub-team-1', 'bar')

      process_jobs

      # Add `other_user` back in to Team 1.

      reload_all integration, team1, team2

      TeamMembershipsService.create_or_update!(
        team: team1,
        user_id: other_user.id,
        role: nil
      )

      expect(TeamMembershipsService.user_a_member_of_team?(team1.id, other_user)).to be true
      expect(TeamMembership.exists?(team: team1, user: other_user)).to be true

      expect(Sidekiq::Worker.jobs.size).to eq 1

      expect(agent).to receive(:add_user_to_team)
        .with('hub-team-1', 'bar')

      process_jobs

      # Now disconnect `other_user`'s identity and check they get removed from the
      # GitHub team(s).

      other_user_identity = other_user.identities.find_by integration: integration
      IdentitiesService.destroy!(other_user_identity)

      expect(Sidekiq::Worker.jobs.size).to eq 1

      expect(agent).to receive(:remove_user_from_team)
        .with('hub-team-1', 'bar')

      expect(agent).to receive(:remove_user_from_team)
        .with('hub-team-2', 'bar')

      process_jobs

      # Now allocate the integration to only Team 1 and check that it synchronises
      # state as expected.

      reload_all integration, team1, team2

      success = Admin::IntegrationsService.update integration, team_ids: [team1.id]

      expect(success).to be true
      expect(integration.reload.team_ids).to contain_exactly team1.id

      expect(Sidekiq::Worker.jobs.size).to eq 1

      expect(agent).to receive(:delete_team)
        .with('hub-team-2')

      # Does a full sync, so also handles syncing of Team 1 too.
      expect(agent).to receive(:create_team)
        .with('hub-team-1', team1.description)
      expect(agent).to receive(:add_user_to_team)
        .with('hub-team-1', 'foo')

      process_jobs

      # Now create a CodeRepo to check it gets assigned the correct team.

      reload_all integration, team1, team2

      team1_project = create :project, team: team1
      code_repo = create :code_repo,
        integration: integration,
        project: team1_project,
        requested_by: user

      ResourceProvisioningService.new.request_create code_repo

      expect(Sidekiq::Worker.jobs.size).to eq 1

      agent_create_repo_response = double(
        private: true,
        full_name: "foo/#{code_repo.name}",
        html_url: "https://github.com/foo/#{code_repo.name}"
      )

      expect(agent).to receive(:create_repository)
        .with(code_repo.name, team_name: 'hub-team-1', auto_init: true)
        .and_return(agent_create_repo_response)

      expect(agent).to receive(:apply_best_practices)
        .with(agent_create_repo_response.full_name)
        .and_return(true)

      process_jobs

      expect(code_repo.reload.active?).to be true

      # Now create a new integration that's available to all teams, and thus
      # should sync up existing teams as expected.

      reload_all integration, team1, team2

      other_integration_config = {
        'org' => 'org_bar',
        'app_id' => 12_345,
        'app_private_key' => 'bar_private_key',
        'app_installation_id' => 1_010_101,
        'app_client_id' => 'app client id',
        'app_client_secret' => 'supersecret',
        'enforce_best_practices' => false
      }

      other_integration, success = Admin::IntegrationsService.create(
        name: 'Integration 2',
        provider_id: 'git_hub',
        config: other_integration_config
      )

      expect(success).to be true
      expect(Integration.count).to be 2
      expect(other_integration.git_hub?).to be true

      expect(Sidekiq::Worker.jobs.size).to eq 1

      other_agent_initializer_params = other_integration_config.symbolize_keys.except(
        :enforce_best_practices,
        :app_client_id,
        :app_client_secret
      )
      other_agent = instance_double(GitHubAgent)
      expect(GitHubAgent).to receive(:new)
        .with(**other_agent_initializer_params)
        .and_return(other_agent)
        .at_least(:once)

      expect(other_agent).to receive(:create_team)
        .with('hub-team-1', team1.description)

      expect(other_agent).to receive(:create_team)
        .with('hub-team-2', team2.description)

      process_jobs

      # Now connect up `other_user`'s identity on `other_integration` and check.

      reload_all integration, other_integration, team1, team2

      IdentitiesService.create!(
        other_integration.user_identities,
        user: other_user,
        external_id: 234,
        external_username: 'bar',
        external_name: 'Bar',
        external_email: 'bar@example.com',
        access_token: 'this is another very very long token, I think'
      )

      expect(Sidekiq::Worker.jobs.size).to eq 1

      expect(other_agent).to receive(:add_user_to_team)
        .with('hub-team-1', 'bar')
      expect(other_agent).to receive(:add_user_to_team)
        .with('hub-team-2', 'bar')

      process_jobs

      # Create another team: Team 3 and check that only `other_integration` is
      # used to sync teams for it.

      reload_all integration, other_integration, team1, team2

      team3, success = TeamsService.create(
        {
          name: 'Team 3',
          slug: 'team-3',
          description: 'This is Team numero tres'
        },
        user
      )
      expect(success).to be true
      expect(team3.slug).to eq 'team-3'

      # `user` should've been made an admin of the team automatically.
      expect(TeamMembershipsService.user_an_admin_of_team?(team3.id, user)).to be true
      expect(TeamMembership.exists?(team: team3, user: user, role: 'admin')).to be true

      expect(Sidekiq::Worker.jobs.size).to eq 2

      expect(other_agent).to receive(:create_team)
        .with('hub-team-3', team3.description)

      process_jobs

      # Now delete Team 2 and check that things get synced up as expected.

      reload_all integration, other_integration, team1, team2, team3

      TeamsService.destroy! team2

      expect(Sidekiq::Worker.jobs.size).to eq 1

      expect(agent).to receive(:delete_team)
        .with('hub-team-2')
        .never

      expect(other_agent).to receive(:delete_team)
        .with('hub-team-2')

      process_jobs

      # Now make the first integration "open" again and check that it synchronises
      # state as expected.

      reload_all integration, other_integration, team1, team3

      success = Admin::IntegrationsService.update integration, team_ids: []

      expect(success).to be true
      expect(integration.reload.team_ids).to be_empty

      expect(Sidekiq::Worker.jobs.size).to eq 1

      expect(agent).to receive(:create_team)
        .with('hub-team-1', team1.description)
      expect(agent).to receive(:add_user_to_team)
        .with('hub-team-1', 'foo')
      expect(agent).to receive(:add_user_to_team)
        .with('hub-team-1', 'bar')
        .never

      expect(agent).to receive(:create_team)
        .with('hub-team-2', team2.description)
        .never

      expect(agent).to receive(:create_team)
        .with('hub-team-3', team3.description)
      expect(agent).to receive(:add_user_to_team)
        .with('hub-team-3', 'foo')

      process_jobs
    end
  end
end
