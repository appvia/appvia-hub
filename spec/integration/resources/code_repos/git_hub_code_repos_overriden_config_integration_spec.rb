require 'rails_helper'

RSpec.describe 'Code Repo - GitHub - with overriden config option' do
  let! :provisioning_service do
    ResourceProvisioningService.new
  end

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

  let! :integration do
    create :integration,
      provider_id: provider_id,
      config: integration_config
  end

  let! :resource do
    create :code_repo, integration: integration
  end

  let! :integration_override do
    create :integration_override,
      project: resource.project,
      integration: integration,
      config: {
        'enforce_best_practices' => !integration_config['enforce_best_practices']
      }
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

  let :agent do
    instance_double(agent_class)
  end

  let :agent_create_response do
    double(
      private: true,
      full_name: "foo/#{resource.name}",
      html_url: "https://github.com/foo/#{resource.name}"
    )
  end

  before do
    expect(agent_class).to receive(:new)
      .with(**agent_initializer_params)
      .and_return(agent)

    allow(ResourceProvisioningService).to receive(:new)
      .and_return(provisioning_service)
  end

  describe 'request create' do
    it 'agent should receive the overriden config option' do
      expect(agent).to receive(:create_repository)
        .with(resource.name, team_id: 1000, best_practices: !integration_config['enforce_best_practices'])
        .and_return(agent_create_response)

      expect do
        provisioning_service.request_create resource
      end.to change(Resources::RequestCreateWorker.jobs, :size).by(1)

      expect(resource.status).to eq Resource.statuses[:pending]

      expect(resource.audits.order(:created_at).last.action).to eq 'request_create'

      Resources::RequestCreateWorker.perform_one

      updated = Resource.find resource.id

      expect(updated.name).to eq resource.name
      expect(updated.status).to eq Resource.statuses[:active]
      expect(updated.private).to eq agent_create_response.private
      expect(updated.full_name).to eq agent_create_response.full_name
      expect(updated.url).to eq agent_create_response.html_url
      expect(updated.enforce_best_practices).to eq !integration_config['enforce_best_practices']
    end
  end
end
