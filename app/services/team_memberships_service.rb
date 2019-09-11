module TeamMembershipsService
  class << self
    def user_a_member_of_team?(team_id, user_id)
      TeamMembership.exists? team_id: team_id, user_id: user_id
    end

    def user_an_admin_of_team?(team_id, user_id)
      TeamMembership.admin.exists? team_id: team_id, user_id: user_id
    end

    def create_or_update!(team:, user_id:, role:)
      team_membership = team_membership_scope_for_user(
        team,
        user_id
      ).first_or_initialize

      team_membership.role = role if role.present?

      is_a_new_record = team_membership.new_record?

      team_membership.save!

      Teams::HandleTeamMembershipCreatedWorker.perform_async(team_membership.id) if is_a_new_record

      team_membership
    end

    def destroy!(team:, user_id:)
      team_membership = team_membership_scope_for_user(
        team,
        user_id
      ).first

      if team_membership.present?
        slug = team.slug
        integration_ids = TeamIntegrationsService.get(team).map(&:id)

        team_membership.destroy!

        Teams::HandleTeamMembershipDeletedWorker.perform_async(
          slug,
          user_id,
          integration_ids
        )
      end

      team_membership
    end

    private

    def team_membership_scope_for_user(team, user_id)
      team
        .memberships
        .where(user_id: user_id)
    end
  end
end
