module AllocationTestModels
  RSpec.shared_context 'allocation test models' do
    with_model :AllocatableModel do
      table id: :uuid, &:timestamps

      model do
        include Allocatable
        allocatable

        def descriptor
          'N/A'
        end
      end
    end

    with_model :AllocationReceivableModel do
      table id: :uuid, &:timestamps

      model do
        include AllocationReceivable
        allocation_receivable

        def descriptor
          'N/A'
        end
      end
    end
  end
end
