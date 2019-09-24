class Team < ApplicationRecord
  include SluggedAttribute
  include FriendlyId
  include AllocationReceivable

  audited
  has_associated_audits

  slugged_attribute :slug,
    presence: true,
    uniqueness: true,
    readonly: true

  friendly_id :slug

  allocation_receivable

  validates :name, presence: true

  has_many :integrations,
    through: :allocations,
    source: :allocatable,
    source_type: Integration.name

  has_many :projects,
    -> { order(:name) },
    dependent: :restrict_with_exception,
    inverse_of: :team

  has_many :memberships,
    class_name: 'TeamMembership',
    dependent: :destroy

  has_many :members,
    through: :memberships,
    source: :user

  def descriptor
    slug
  end
end
