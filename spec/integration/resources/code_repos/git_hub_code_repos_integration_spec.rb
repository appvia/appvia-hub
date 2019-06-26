require 'rails_helper'

RSpec.describe 'Code Repos - GitHub' do
  include_examples 'resource integration specs' do
    let(:provider_id) { 'git_hub' }

    let :integration_config do
      {
        'org' => 'foo',
        'all_team_id' => 1000,
        'app_id' => 12_345,
        'app_private_key' => 'foo_private_key',
        'app_installation_id' => 1_010_101,
        'app_client_id' => 'app client id',
        'app_client_secret' => 'supersecret',
        'enforce_best_practices' => true
      }
    end

    let! :resource do
      create :code_repo, integration: integration
    end

    let(:agent_class) { GitHubAgent }
    let :agent_initializer_params do
      integration_config.symbolize_keys.except(
        :all_team_id,
        :enforce_best_practices,
        :app_client_id,
        :app_client_secret
      )
    end

    let :agent_create_response do
      double(
        private: true,
        full_name: "foo/#{resource.name}",
        html_url: "https://github.com/foo/#{resource.name}"
      )
    end

    let :agent_create_method_call_success do
      lambda do |agent, resource|
        expect(agent).to receive(:create_repository)
          .with(resource.name, team_id: 1000, best_practices: true)
          .and_return(agent_create_response)
      end
    end

    let :request_create_finished_success_expectations do
      lambda do |updated|
        expect(updated.private).to eq agent_create_response.private
        expect(updated.full_name).to eq agent_create_response.full_name
        expect(updated.url).to eq agent_create_response.html_url
        expect(updated.enforce_best_practices).to eq true
      end
    end

    let :agent_create_method_call_error do
      lambda do |agent, resource|
        expect(agent).to receive(:create_repository)
          .with(resource.name, team_id: 1000, best_practices: true)
          .and_raise('Something broked')
      end
    end

    let :request_create_finished_error_expectations do
      lambda do |updated|
        expect(updated.private).to eq nil
        expect(updated.full_name).to eq nil
        expect(updated.url).to eq nil
        expect(updated.enforce_best_practices).to eq false
      end
    end

    let :request_delete_before_setup_resource_state do
      lambda do |resource|
        resource.full_name = "foo/#{resource.name}"
      end
    end

    let :agent_delete_method_call_success do
      lambda do |agent, resource|
        expect(agent).to receive(:delete_repository)
          .with(resource.full_name)
          .and_return(true)
      end
    end

    let :agent_delete_method_call_error do
      lambda do |agent, resource|
        expect(agent).to receive(:delete_repository)
          .with(resource.full_name)
          .and_raise('Something broked')
      end
    end
  end
end
