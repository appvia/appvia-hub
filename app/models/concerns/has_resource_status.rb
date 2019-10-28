module HasResourceStatus
  extend ActiveSupport::Concern

  included do
    enum status: {
      pending: 'pending',
      active: 'active',
      deleting: 'deleting',
      failed: 'failed'
    }

    validates :status, presence: true

    default_value_for :status, :pending
  end
end
