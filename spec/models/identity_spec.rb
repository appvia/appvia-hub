require 'rails_helper'

RSpec.describe Identity, type: :model do
  subject do
    user = create :user

    # User needs to be in at least one team to access integrations
    create :team_membership, user: user

    create :identity, user: user, integration: create_mocked_integration
  end

  describe '#user' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_readonly_attribute(:user_id) }
  end

  describe '#integration' do
    it { is_expected.to belong_to(:integration).class_name('Integration') }
    it { is_expected.to have_readonly_attribute(:integration_id) }
  end

  describe 'check_integration_is_allowed custom validation' do
    let(:user) { create :user }

    let(:team) { create :team }
    let(:other_team) { create :team }

    let(:integration_1) { create_mocked_integration }
    let(:integration_2) { create_mocked_integration }
    let(:integration_3) { create_mocked_integration }

    before do
      create :allocation, allocatable: integration_2, allocation_receivable: team
      create :allocation, allocatable: integration_3, allocation_receivable: other_team

      create :team_membership, user: user, team: team
    end

    context 'for an integration that\'s open to all users' do
      it 'allows using the integration' do
        identity = build :identity, user: user, integration: integration_1
        expect(identity).to be_valid
      end
    end

    context 'for an integration that\'s allocated to a team the user is in' do
      it 'allows using the integration' do
        identity = build :identity, user: user, integration: integration_2
        expect(identity).to be_valid
      end
    end

    context 'for an integration that\'s allocated to a team the user is not in' do
      it 'doesn\'t allow using the integration' do
        identity = build :identity, user: user, integration: integration_3
        expect(identity).not_to be_valid
        expect(identity.errors[:integration]).to be_present
      end
    end
  end
end
