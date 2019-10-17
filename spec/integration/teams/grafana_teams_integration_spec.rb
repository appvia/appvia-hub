require 'rails_helper'

RSpec.describe 'Grafana teams end-to-end' do
  include_context 'time helpers'

  let(:provider_id) { 'grafana' }
  let(:grafana_agent_class) { GrafanaAgent }
  let(:kubernetes_agent_class) { KubernetesAgent }

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
      expect(grafana_agent_class).to receive(:new).never
    end

    it 'doesn\'t perform any synchronisation of grafana users' do
      team1, success = TeamsService.create(
        {
          name: 'Grafana Team',
          slug: 'grafana-team',
          description: 'This is a grafana team'
        },
        user
      )
      expect(success).to be true
      expect(team1.slug).to eq 'grafana-team'

      expect(Sidekiq::Worker.jobs.size).to eq 2

      expect_any_instance_of(grafana_agent_class).to receive(:sync_team).never

      process_jobs

      reload_all team1

      TeamsService.destroy! team1

      expect(Sidekiq::Worker.jobs.size).to eq 1

      expect_any_instance_of(grafana_agent_class).to receive(:sync_team).never

      process_jobs
    end
  end

  context 'with integrations' do

    let :kubernetes_integration_config do
      {
        'cluster_name' => 'Our Kube Cluster',
        'api_url' => 'url-to-kube-api',
        'ca_cert' => 'kube CA cert',
        'token' => 'kube API token'
      }
    end

    let :kubernetes_agent_initializer_params do
      {
        agent_base_url: Rails.configuration.agents.kubernetes.base_url,
        agent_token: Rails.configuration.agents.kubernetes.token,
        kube_api_url: kubernetes_integration_config['api_url'],
        kube_ca_cert: kubernetes_integration_config['ca_cert'],
        kube_token: kubernetes_integration_config['token']
      }
    end
    let(:kubernetes_agent) { instance_double(kubernetes_agent_class) }

    let :grafana_integration_config do
      {
        'url' => 'http://grafana',
        'api_key' => 'this is an API key, no really',
        'ca_cert' => 'ca cert base64 encoded',
        'template_url' => 'http://url.to.my.template/foo',
        'admin_username' => 'admin',
        'admin_password' => 'this is an admin password, I promise'
      }
    end

    let(:grafana_agent_class) { GrafanaAgent }
    let :grafana_agent_initializer_params do
      {
        agent_base_url: Rails.configuration.agents.grafana.base_url,
        agent_token: Rails.configuration.agents.grafana.token,
        url: grafana_integration_config['url'],
        api_key: grafana_integration_config['api_key'],
        ca_cert: grafana_integration_config['ca_cert'],
        admin_username: grafana_integration_config['admin_username'],
        admin_password: grafana_integration_config['admin_password']
      }
    end
    let(:agent) { instance_double(grafana_agent_class) }

    it 'synchronises users with grafana' do
      # Create a kubernetes and grafana integration

      expect(Integration.count).to be 0

      kubernetes_integration, kubernetes_integration_success = Admin::IntegrationsService.create(
        name: 'Kubernetes Integration',
        provider_id: 'kubernetes',
        config: kubernetes_integration_config
      )

      expect(kubernetes_integration_success).to be true
      expect(Integration.count).to be 1
      expect(kubernetes_integration.kubernetes?).to be true

      expect(Sidekiq::Worker.jobs.size).to eq 1

      grafana_integration, grafana_success = Admin::IntegrationsService.create(
        name: 'Grafana Integration',
        provider_id: 'grafana',
        config: grafana_integration_config,
        parent_ids: [kubernetes_integration.id]
      )

      expect(grafana_success).to be true
      expect(Integration.count).to be 2
      expect(grafana_integration.grafana?).to be true

      expect(Sidekiq::Worker.jobs.size).to eq 2

      team1, success = TeamsService.create(
        {
          name: 'Grafana Team',
          slug: 'grafana-team',
          description: 'This is a grafana team'
        },
        user
      )
      expect(success).to be true
      expect(team1.slug).to eq 'grafana-team'

      expect(Sidekiq::Worker.jobs.size).to eq 4

      expect_any_instance_of(grafana_agent_class).to receive(:sync_team)

      process_jobs

      reload_all team1
    end
  end
end
