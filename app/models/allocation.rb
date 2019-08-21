class Allocation < ApplicationRecord
  audited associated_with: :allocation_receivable

  belongs_to :allocatable,
    -> { readonly },
    polymorphic: true,
    inverse_of: :allocations

  belongs_to :allocation_receivable,
    -> { readonly },
    polymorphic: true,
    inverse_of: :allocations

  validate :ensure_uniqueness

  scope :by_allocatable, ->(a) { where(allocatable: a) }
  scope :by_allocation_receivable, ->(ar) { where(allocation_receivable: ar) }

  attr_readonly :allocatable_type, :allocatable_id, :allocation_receivable_type, :allocation_receivable_id

  def descriptor
    [
      "#{allocatable_type}: #{allocatable.descriptor}",
      '|',
      "#{allocation_receivable_type}: #{allocation_receivable.descriptor}"
    ].join(' ')
  end

  private

  def ensure_uniqueness
    return if allocatable.blank? || allocation_receivable.blank?

    if Allocation.where(
      allocatable: allocatable,
      allocation_receivable: allocation_receivable
    ).exists?
      errors[:base] << 'An allocation already exists for this'
    end
  end
end
