module Teams
  class HandleIdentityCreatedWorker < BaseWorker
    def perform(identity_id)
      identity = Identity.find_by id: identity_id

      return if identity.nil?

      integration = identity.integration

      teams = TeamIntegrationsService.get_teams_for integration

      teams.each do |t|
        process_team(
          t,
          integration,
          identity
        )
      end
    end

    private

    def process_team(team, integration, identity)
      membership = team.memberships.find_by user_id: identity.user_id

      return if membership.nil?

      SyncIntegrationTeamService.sync_team_membership integration, membership
    rescue StandardError => e
      logger.error [
        "Failed to process team #{team.slug}",
        "for integration #{integration.id}",
        "(provider: #{integration.provider_id}, name: #{integration.name})",
        "for identity #{identity.id}",
        "- error: #{e.message} - #{e.backtrace.first}"
      ].join(' ')
    end
  end
end
