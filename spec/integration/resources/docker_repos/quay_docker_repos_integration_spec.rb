require 'rails_helper'

RSpec.describe 'Docker Repos – Quay' do
  include_examples 'resource integration specs' do
    let(:provider_id) { 'quay' }

    let :integration_config do
      {
        'api_access_token' => 'quay API token',
        'org' => 'foo'
      }
    end

    let! :resource do
      create :docker_repo, integration: integration
    end

    let(:agent_class) { QuayAgent }
    let :agent_initializer_params do
      {
        agent_base_url: Rails.configuration.agents.quay.base_url,
        agent_token: Rails.configuration.agents.quay.token,
        quay_access_token: integration_config['api_access_token'],
        org: integration_config['org']
      }
    end

    let :agent_create_response do
      double(
        spec: double(
          visibility: 'private',
          url: "quay.io/foo/#{resource.name}"
        )
      )
    end

    let :agent_create_method_call_success do
      lambda do |agent, resource|
        expect(agent).to receive(:create_repository)
          .with(resource.name, robots: [])
          .and_return(agent_create_response)
      end
    end

    let :request_create_finished_success_expectations do
      lambda do |updated|
        expect(updated.visibility).to eq agent_create_response.spec.visibility
        expect(updated.base_uri).to eq agent_create_response.spec.url
      end
    end

    let :agent_create_method_call_error do
      lambda do |agent, resource|
        expect(agent).to receive(:create_repository)
          .with(resource.name, robots: [])
          .and_raise('Something broked')
      end
    end

    let :request_create_finished_error_expectations do
      lambda do |updated|
        expect(updated.visibility).to eq nil
        expect(updated.base_uri).to eq nil
      end
    end

    let :request_delete_before_setup_resource_state do
      lambda do |resource|
      end
    end

    let :agent_delete_method_call_success do
      lambda do |agent, resource|
        expect(agent).to receive(:delete_repository)
          .with(resource.name)
          .and_return(true)
      end
    end

    let :agent_delete_method_call_error do
      lambda do |agent, resource|
        expect(agent).to receive(:delete_repository)
          .with(resource.name)
          .and_raise('Something broked')
      end
    end
  end
end
