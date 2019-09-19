module Teams
  class HandleIdentityDeletedWorker < BaseWorker
    def perform(integration_id, external_info)
      integration = Integration.find_by id: integration_id

      return if integration.nil?

      teams = TeamIntegrationsService.get_teams_for integration

      teams.each do |t|
        process_team(
          t,
          integration,
          external_info
        )
      end
    end

    private

    def process_team(team, integration, external_info)
      SyncIntegrationTeamService.remove_team_membership(
        integration,
        team.slug,
        external_info['Username']
      )
    rescue StandardError => e
      logger.error [
        "Failed to process team #{team.slug}",
        "for integration #{integration.id}",
        "(provider: #{integration.provider_id}, name: #{integration.name})",
        "for external username #{external_info['Username']}",
        "- error: #{e.message} - #{e.backtrace.first}"
      ].join(' ')
    end
  end
end
