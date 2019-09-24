module Teams
  class HandleTeamMembershipDeletedWorker < BaseWorker
    def perform(team_slug, user_id, integration_ids)
      user = User.find_by id: user_id

      return if user.nil?

      integration_ids.each do |id|
        integration = Integration.find_by id: id

        next if integration.nil?

        identity = user.identities.find_by integration_id: integration.id

        next if identity.nil?

        process_integration(
          integration,
          team_slug,
          identity
        )
      end
    end

    private

    def process_integration(integration, team_slug, identity)
      SyncIntegrationTeamService.remove_team_membership(
        integration,
        team_slug,
        identity.external_username
      )
    rescue StandardError => e
      logger.error [
        "Failed to process integration #{integration.id}",
        "(provider: #{integration.provider_id}, name: #{integration.name})",
        "for team #{team_slug}",
        "for external username #{identity.external_username}",
        "- error: #{e.message} - #{e.backtrace.first}"
      ].join(' ')
    end
  end
end
