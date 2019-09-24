module Teams
  class HandleTeamDeletedWorker < BaseWorker
    def perform(team_slug, integration_ids)
      integration_ids.each do |id|
        integration = Integration.find_by id: id

        next if integration.nil?

        process_integration integration, team_slug
      end
    end

    private

    def process_integration(integration, team_slug)
      SyncIntegrationTeamService.remove_team integration, team_slug
    rescue StandardError => e
      logger.error [
        "Failed to process integration #{integration.id}",
        "(provider: #{integration.provider_id}, name: #{integration.name})",
        "for team #{team_slug}",
        "- error: #{e.message} - #{e.backtrace.first}"
      ].join(' ')
    end
  end
end
