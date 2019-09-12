require 'rails_helper'

RSpec.describe Allocatable, type: :model do
  include_context 'allocation test models'

  describe '#unallocated scope' do
    context 'with no allocations made' do
      it 'should return an empty list' do
        expect(AllocatableModel.unallocated.entries).to eq []
      end
    end

    context 'with some allocations made' do
      let!(:unallocated_item_1) { AllocatableModel.create! }
      let!(:unallocated_item_2) { AllocatableModel.create! }
      let!(:allocated_item_1) { AllocatableModel.create! }
      let!(:allocated_item_2) { AllocatableModel.create! }

      before do
        Allocation.create!(
          allocatable: allocated_item_1,
          allocation_receivable: AllocationReceivableModel.create!
        )

        Allocation.create!(
          allocatable: allocated_item_2,
          allocation_receivable: AllocationReceivableModel.create!
        )

        Allocation.create!(
          allocatable: allocated_item_2,
          allocation_receivable: AllocationReceivableModel.create!
        )
      end

      it 'returns only those allocatable items that have not been allocated at least once' do
        expect(AllocatableModel.unallocated.pluck(:id)).to contain_exactly(unallocated_item_1.id, unallocated_item_2.id)
      end
    end
  end
end
