require 'rails_helper'

RSpec.describe TeamIntegrationsService, type: :service do
  describe '.get' do
    let!(:team_1) { create :team }
    let!(:team_2) { create :team }

    let!(:integration_1) do
      create_mocked_integration provider_id: 'git_hub'
    end
    let!(:integration_2) do
      create_mocked_integration provider_id: 'quay'
    end
    let!(:integration_3) do
      create_mocked_integration provider_id: 'kubernetes'
    end
    let!(:integration_4) do
      create_mocked_integration provider_id: 'kubernetes'
    end
    let!(:integration_3_dependent) do
      create_mocked_integration provider_id: 'grafana', parent_ids: [integration_3.id]
    end
    let!(:integration_4_dependent) do
      create_mocked_integration provider_id: 'grafana', parent_ids: [integration_4.id]
    end

    before do
      create :allocation, allocatable: integration_2, allocation_receivable: team_1
      create :allocation, allocatable: integration_4, allocation_receivable: team_2
    end

    context 'when `include_dependents` is `false` (default)' do
      it 'returns the appropriate integrations for each team' do
        expect(
          TeamIntegrationsService.get(team_1)
        ).to contain_exactly(
          integration_1,
          integration_2,
          integration_3
        )

        expect(
          TeamIntegrationsService.get(team_2)
        ).to contain_exactly(
          integration_1,
          integration_3,
          integration_4
        )
      end
    end

    context 'when `include_dependents` is `true`' do
      it 'returns the appropriate integrations for each team' do
        expect(
          TeamIntegrationsService.get(team_1, include_dependents: true)
        ).to contain_exactly(
          integration_1,
          integration_2,
          integration_3,
          integration_3_dependent
        )

        expect(
          TeamIntegrationsService.get(team_2, include_dependents: true)
        ).to contain_exactly(
          integration_1,
          integration_3,
          integration_3_dependent,
          integration_4,
          integration_4_dependent
        )
      end
    end
  end
end
