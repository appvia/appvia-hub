require 'rails_helper'

RSpec.describe 'Monitoring Dashboards – Grafana' do
  include_examples 'resource integration specs' do
    let(:provider_id) { 'grafana' }

    let :integration_config do
      {
        'url' => 'http://grafana',
        'api_key' => 'this is an API key, no really',
        'ca_cert' => 'ca cert base64 encoded',
        'template_url' => 'http://url.to.my.template/foo',
        'admin_username' => 'admin',
        'admin_password' => 'this is an admin password, I promise'
      }
    end

    let :parent_integration do
      create_mocked_integration provider_id: 'kubernetes'
    end

    let! :parent do
      create :kube_namespace, integration: parent_integration
    end

    let! :resource do
      create :monitoring_dashboard,
        parent: parent,
        integration: integration
    end

    let(:agent_class) { GrafanaAgent }
    let :agent_initializer_params do
      {
        agent_base_url: Rails.configuration.agents.grafana.base_url,
        agent_token: Rails.configuration.agents.grafana.token,
        grafana_url: integration_config['url'],
        grafana_api_key: integration_config['api_key'],
        grafana_ca_cert: integration_config['ca_cert'],
        grafana_admin_username: integration_config['admin_username'],
        grafana_admin_password: integration_config['admin_password']
      }
    end

    let :agent_create_response do
      double(
        url: 'http://grafana/my-new-dashboard'
      )
    end

    let :agent_create_method_call_success do
      lambda do |agent, resource|
        expect(agent).to receive(:create_dashboard)
          .with(resource.name, template_url: integration_config['template_url'])
          .and_return(agent_create_response)
      end
    end

    let :request_create_finished_success_expectations do
      lambda do |updated|
        expect(updated.url).to eq agent_create_response.url
      end
    end

    let :agent_create_method_call_error do
      lambda do |agent, resource|
        expect(agent).to receive(:create_dashboard)
          .with(resource.name, template_url: integration_config['template_url'])
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
        expect(agent).to receive(:delete_dashboard)
          .with(resource.name)
          .and_return(true)
      end
    end

    let :agent_delete_method_call_error do
      lambda do |agent, resource|
        expect(agent).to receive(:delete_dashboard)
          .with(resource.name)
          .and_raise('Something broked')
      end
    end
  end
end
