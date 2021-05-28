module Teams
  class HandleTeamMembershipCreatedWorker < BaseWorker
    def perform(team_membership_id)
      team_membership = TeamMembership.find_by id: team_membership_id

      return if team_membership.nil?

      integrations = TeamIntegrationsService.get(team_membership.team, include_dependents: true)

      return if integrations.blank?

      integrations.each do |i|
        process_integration i, team_membership
      end
    end

    private

    def process_integration(integration, team_membership)
      SyncIntegrationTeamService.sync_team_membership integration, team_membership
    rescue StandardError => e
      logger.error [
        "Failed to process integration #{integration.id}",
        "(provider: #{integration.provider_id}, name: #{integration.name})",
        "for team membership #{team_membership.id}",
        "- error: #{e.message} - #{e.backtrace.first}"
      ].join(' ')
    end
  end
end
