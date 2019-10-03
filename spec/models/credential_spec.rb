require 'rails_helper'

RSpec.describe Credential, type: :model do
  subject do
    project = create :project

    create :credential, integration: create_mocked_integration, owner: project
  end

  describe '#integration' do
    it { is_expected.to belong_to(:integration).class_name('Integration') }
    it { is_expected.to have_readonly_attribute(:integration_id) }
  end

  describe '#name' do
    include_examples 'slugged_attribute',
      :name,
      presence: true,
      uniqueness: { scope: :integration_id },
      readonly: true
  end

  describe 'check_integration_is_allowed custom validation' do
    let!(:user) { create :user }

    let!(:team) { create :team }
    let!(:other_team) { create :team }

    let!(:project) { create :project, team: team }
    let!(:other_project) { create :project, team: other_team }

    let(:integration_1) { create_mocked_integration }
    let(:integration_2) { create_mocked_integration }
    let(:integration_3) { create_mocked_integration }

    before do
      create :allocation, allocatable: integration_2, allocation_receivable: team
      create :allocation, allocatable: integration_3, allocation_receivable: other_team

      create :team_membership, user: user, team: team
    end

    context 'for an integration that\'s open' do
      let(:integration) { integration_1 }

      it 'allows the owner to be the user' do
        credential = build :credential, owner: user, integration: integration
        expect(credential).to be_valid
      end

      it 'allows the owner to be the team' do
        credential = build :credential, owner: team, integration: integration
        expect(credential).to be_valid
      end

      it 'allows the owner to be the other team' do
        credential = build :credential, owner: other_team, integration: integration
        expect(credential).to be_valid
      end

      it 'allows the owner to be the project' do
        credential = build :credential, owner: project, integration: integration
        expect(credential).to be_valid
      end

      it 'allows the owner to be the other project' do
        credential = build :credential, owner: other_project, integration: integration
        expect(credential).to be_valid
      end
    end

    context 'for an integration that\'s allocated to a team the user is in' do
      let(:integration) { integration_2 }

      it 'allows the owner to be the user' do
        credential = build :credential, owner: user, integration: integration
        expect(credential).to be_valid
      end

      it 'allows the owner to be the team' do
        credential = build :credential, owner: team, integration: integration
        expect(credential).to be_valid
      end

      it 'doesn\'t allow the owner to be the other team' do
        credential = build :credential, owner: other_team, integration: integration
        expect(credential).not_to be_valid
        expect(credential.errors[:integration]).to be_present
      end

      it 'allows the owner to be the project' do
        credential = build :credential, owner: project, integration: integration
        expect(credential).to be_valid
      end

      it 'doesn\'t allow the owner to be the other project' do
        credential = build :credential, owner: other_project, integration: integration
        expect(credential).not_to be_valid
        expect(credential.errors[:integration]).to be_present
      end
    end

    context 'for an integration that\'s allocated to a team the user is not in' do
      let(:integration) { integration_3 }

      it 'doesn\'t allow the owner to be the user' do
        credential = build :credential, owner: user, integration: integration
        expect(credential).not_to be_valid
        expect(credential.errors[:integration]).to be_present
      end

      it 'doesn\'t allow the owner to be the team' do
        credential = build :credential, owner: team, integration: integration
        expect(credential).not_to be_valid
        expect(credential.errors[:integration]).to be_present
      end

      it 'allows the owner to be the other team' do
        credential = build :credential, owner: other_team, integration: integration
        expect(credential).to be_valid
      end

      it 'doesn\'t allow the owner to be the project' do
        credential = build :credential, owner: project, integration: integration
        expect(credential).not_to be_valid
        expect(credential.errors[:integration]).to be_present
      end

      it 'allows the owner to be the other project' do
        credential = build :credential, owner: other_project, integration: integration
        expect(credential).to be_valid
      end
    end
  end
end
