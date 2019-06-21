require 'rails_helper'

RSpec.describe 'Logging Dashboards – Loki' do
  include_examples 'resource integration specs' do
    let(:provider_id) { 'loki' }

    let :integration_config do
      {
        'grafana_url' => 'http://grafana',
        'loki_data_source_name' => 'Loki'
      }
    end

    let! :parent do
      kubernetes_integration = create_mocked_integration provider_id: 'kubernetes'
      create :kube_namespace, integration: kubernetes_integration
    end

    let! :resource do
      create :logging_dashboard,
        parent: parent,
        integration: integration
    end

    let(:agent_class) { LokiAgent }
    let :agent_initializer_params do
      {
        grafana_url: integration_config['grafana_url'],
        loki_data_source_name: integration_config['loki_data_source_name']
      }
    end

    let :agent_create_response do
      'http://grafana/explore%3Fleft%3D%5B%22now-6h%22%2C%22now%22%2C%22Loki%22%2C%7B%22' \
      "expr%22%3A%22%7Bnamespace%3D%5C%22#{resource.name}%5C%22%7D%22%7D%2C%7B%22ui%22%3A" \
      '%5Btrue%2Ctrue%2Ctrue%2C%22none%22%5D%7D%5D'
    end

    let :agent_create_method_call_success do
      lambda do |agent, resource|
        expect(agent).to receive(:create_logging_dashboard)
          .with('{namespace=\"' + resource.name + '\"}')
          .and_return(agent_create_response)
      end
    end

    let :request_create_finished_success_expectations do
      lambda do |updated|
        expect(updated.url).to eq agent_create_response
      end
    end

    let :agent_create_method_call_error do
      lambda do |agent, resource|
        expect(agent).to receive(:create_logging_dashboard)
          .with('{namespace=\"' + resource.name + '\"}')
          .and_raise('Something broked')
      end
    end

    let :request_create_finished_error_expectations do
      lambda do |updated|
        expect(updated.url).to eq nil
      end
    end

    let :request_delete_before_setup_resource_state do
      lambda do |resource|
      end
    end

    let :agent_delete_method_call_success do
      lambda do |agent, resource|
        expect(agent).to receive(:delete_logging_dashboard)
          .with(resource.name)
          .and_return(true)
      end
    end

    let :agent_delete_method_call_error do
      lambda do |agent, resource|
        expect(agent).to receive(:delete_logging_dashboard)
          .with(resource.name)
          .and_raise('Something broked')
      end
    end
  end
end
