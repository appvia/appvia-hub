class User < ApplicationRecord
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

  def descriptor
    email
  end

  private

  def normalise_email
    self.email = email.presence.try(:downcase)
  end
end
