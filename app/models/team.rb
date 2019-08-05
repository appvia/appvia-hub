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

  def descriptor
    slug
  end
end
