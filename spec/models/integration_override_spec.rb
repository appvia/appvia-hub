require 'rails_helper'

RSpec.describe IntegrationOverride, type: :model do
  subject do
    create :integration_override, integration: create_mocked_integration
  end

  describe '#project' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to have_readonly_attribute(:project_id) }
  end

  describe '#integration' do
    it { is_expected.to belong_to(:integration).class_name('Integration') }
    it { is_expected.to have_readonly_attribute(:integration_id) }
  end

  describe 'check_integration_is_allowed custom validation' do
    let(:project) { create :project }
    let(:other_project) { create :project }

    let(:integration_1) { create_mocked_integration }
    let(:integration_2) { create_mocked_integration }

    before do
      create :allocation, allocatable: integration_2, allocation_receivable: other_project.team
    end

    context 'for an integration that\'s open to all projects' do
      it 'allows using the integration' do
        override = build :integration_override, project: project, integration: integration_1
        expect(override).to be_valid
      end
    end

    context 'for an integration that\'s not accessible to the project' do
      it 'doesn\'t allow using the integration' do
        override = build :integration_override, project: project, integration: integration_2
        expect(override).not_to be_valid
        expect(override.errors[:integration]).to be_present
      end
    end
  end
end
