require 'rails_helper'

RSpec.describe Resource, type: :model do
  let :test_class do
    Class.new(Resource) {}
  end

  let(:project) { create :project }
  let(:user) { create :user }

  let(:other_project) { create :project }

  let(:integration_1) { create_mocked_integration }
  let(:integration_2) { create_mocked_integration }

  before do
    create :allocation, allocatable: integration_2, allocation_receivable: other_project.team
  end

  describe 'check_integration_is_allowed custom validation' do
    context 'for an integration that\'s open to all projects' do
      it 'allows using the integration' do
        resource = test_class.new(
          name: 'resource-1',
          project: project,
          integration: integration_1,
          requested_by: user
        )
        expect(resource).to be_valid
      end
    end

    context 'for an integration that\'s not accessible to the project' do
      it 'doesn\'t allow using the integration' do
        resource = test_class.new(
          name: 'resource-1',
          project: project,
          integration: integration_2,
          requested_by: user
        )
        expect(resource).not_to be_valid
        expect(resource.errors[:integration]).to be_present
      end
    end

    context 'when the resource has a parent' do
      it 'still allows using the integration that\'s open to all projects' do
        parent = test_class.new(
          name: 'parent-1',
          project: project,
          integration: integration_1,
          requested_by: user
        )
        resource = test_class.new(
          name: 'resource-1',
          parent: parent,
          project: project,
          integration: integration_2,
          requested_by: user
        )
        expect(resource).to be_valid
      end

      it 'still doesn\'t allow using the integration that\'s not accessible to the project' do
        parent = test_class.new(
          name: 'parent-1',
          project: project,
          integration: integration_2,
          requested_by: user
        )
        resource = test_class.new(
          name: 'resource-1',
          parent: parent,
          project: project,
          integration: integration_2,
          requested_by: user
        )
        expect(resource).not_to be_valid
        expect(resource.errors[:integration]).to be_present
      end
    end
  end
end
