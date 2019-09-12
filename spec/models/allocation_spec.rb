require 'rails_helper'

RSpec.describe Allocation, type: :model do
  include_context 'allocation test models'

  describe 'ensure_uniqueness custom validation' do
    let(:allocatable) { AllocatableModel.create }
    let(:other_allocatable) { AllocatableModel.create }
    let(:allocation_receivable) { AllocationReceivableModel.create }
    let(:other_allocation_receivable) { AllocationReceivableModel.create }

    it 'should not allow allocating the same things more than once' do
      allocation = Allocation.new(
        allocatable: allocatable,
        allocation_receivable: allocation_receivable
      )
      expect(allocation).to be_valid
      allocation.save!

      # Can't create the same allocation
      allocation = Allocation.new(
        allocatable: allocatable,
        allocation_receivable: allocation_receivable
      )
      expect(allocation).not_to be_valid

      # But can still create another allocation for the same receiveable
      allocation = Allocation.new(
        allocatable: other_allocatable,
        allocation_receivable: allocation_receivable
      )
      expect(allocation).to be_valid
      allocation.save!

      # Or still create another allocation of the allocatable
      allocation = Allocation.new(
        allocatable: allocatable,
        allocation_receivable: other_allocation_receivable
      )
      expect(allocation).to be_valid
      allocation.save!
    end
  end
end
