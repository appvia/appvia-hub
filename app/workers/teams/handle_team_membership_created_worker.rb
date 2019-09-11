module Teams
  class HandleTeamMembershipCreatedWorker < BaseWorker
    def perform(team_membership_id)
      team_membership = TeamMembership.find_by id: team_membership_id

      return if team_membership.nil?

      integrations = TeamIntegrationsService.get team_membership.team

      return if integrations.blank?

      integrations.each do |i|
        SyncIntegrationTeamService.sync_team_membership i, team_membership
      end
    end
  end
end
