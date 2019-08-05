class Team < ApplicationRecord
  include SluggedAttribute
  include FriendlyId

  audited

  slugged_attribute :slug,
    presence: true,
    uniqueness: true,
    readonly: true

  friendly_id :slug

  validates :name, presence: true

  has_many :projects,
    -> { order(:name) },
    dependent: :restrict_with_exception,
    inverse_of: :team

  def descriptor
    slug
  end
end
