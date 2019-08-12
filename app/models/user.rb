class User < ApplicationRecord
  include PgSearch::Model

  audited

  enum role: {
    admin: 'admin',
    user: 'user'
  }

  validates :email,
    presence: true,
    uniqueness: true

  validates :role, presence: true

  before_validation :normalise_email

  default_value_for :role, 'user'

  has_many :identities,
    dependent: :destroy

  has_many :memberships,
    class_name: 'TeamMembership',
    dependent: :destroy

  has_many :teams, through: :memberships

  pg_search_scope :search,
    against: {
      name: 'A',
      email: 'B'
    },
    using: {
      tsearch: { prefix: true },
      trigram: {}
    }

  def descriptor
    email
  end

  private

  def normalise_email
    self.email = email.presence.try(:downcase)
  end
end
