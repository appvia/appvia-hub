class TeamMembership < ApplicationRecord
  audited associated_with: :team

  self.primary_keys = :team_id, :user_id

  enum role: {
    admin: 'admin'
  }

  belongs_to :team
  validates :team_id, presence: true

  belongs_to :user
  validates :user_id, presence: true

  attr_readonly :team_id, :user_id

  def descriptor
    "Team: #{team.slug} | User: #{user.email}"
  end
end
