require 'rails_helper'

RSpec.describe 'Kube Namespaces – Kubernetes' do
  include_examples 'resource integration specs' do
    let(:provider_id) { 'kubernetes' }

    let :integration_config do
      {
        'cluster_name' => 'Our Kube Cluster',
        'api_url' => 'url-to-kube-api',
        'ca_cert' => 'kube CA cert',
        'token' => 'kube API token',
        'global_service_account_name' => 'default',
        'global_service_account_token' => 'service account token'
      }
    end

    let! :resource do
      create :kube_namespace, integration: integration
    end

    let(:agent_class) { KubernetesAgent }
    let :agent_initializer_params do
      {
        agent_base_url: Rails.configuration.agents.kubernetes.base_url,
        agent_token: Rails.configuration.agents.kubernetes.token,
        kube_api_url: integration_config['api_url'],
        kube_ca_cert: integration_config['ca_cert'],
        kube_token: integration_config['token'],
        global_service_account_name: integration_config['global_service_account_name']
      }
    end

    let! :grafana_integration do
      create_mocked_integration provider_id: 'grafana', parent_ids: [integration.id]
    end

    let! :loki_integration do
      create_mocked_integration provider_id: 'loki', parent_ids: [integration.id]
    end

    let :dependents do
      [
        {
          type: 'MonitoringDashboard',
          integration: grafana_integration,
          factory: :monitoring_dashboard
        },
        {
          type: 'LoggingDashboard',
          integration: loki_integration,
          factory: :logging_dashboard
        }
      ]
    end

    let :agent_create_response do
      double
    end

    let :agent_create_method_call_success do
      lambda do |agent, resource|
        expect(agent).to receive(:create_namespace)
          .with(resource.name)
          .and_return(agent_create_response)
      end
    end

    let :request_create_finished_success_expectations do
      lambda do |updated|
      end
    end

    let :agent_create_method_call_error do
      lambda do |agent, resource|
        expect(agent).to receive(:create_namespace)
          .with(resource.name)
          .and_raise('Something broked')
      end
    end

    let :request_create_finished_error_expectations do
      lambda do |updated|
      end
    end

    let :request_delete_before_setup_resource_state do
      lambda do |resource|
      end
    end

    let :agent_delete_method_call_success do
      lambda do |agent, resource|
        expect(agent).to receive(:delete_namespace)
          .with(resource.name)
          .and_return(true)
      end
    end

    let :agent_delete_method_call_error do
      lambda do |agent, resource|
        expect(agent).to receive(:delete_namespace)
          .with(resource.name)
          .and_raise('Something broked')
      end
    end
  end
end
