module TeamMembershipsService
  class << self
    def user_a_member_of_team?(team_id, user_id)
      scope.exists? team_id: team_id, user_id: user_id
    end

    def user_an_admin_of_team?(team_id, user_id)
      admin_scope.exists? team_id: team_id, user_id: user_id
    end

    private

    def scope
      TeamMembership
    end

    def admin_scope
      TeamMembership.admin
    end
  end
end
