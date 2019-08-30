module AllocationReceivable
  extend ActiveSupport::Concern

  class_methods do
    def allocation_receivable
      has_many :allocations,
        as: :allocation_receivable,
        dependent: :restrict_with_exception,
        inverse_of: :allocation_receivable
    end
  end
end
