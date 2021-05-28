module Teams
  class HandleTeamCreatedWorker < BaseWorker
    def perform(team_id)
      team = Team.find_by id: team_id

      return if team.nil?

      integrations = TeamIntegrationsService.get(team, include_dependents: true)

      return if integrations.blank?

      integrations.each do |i|
        process_integration i, team
      end
    end

    private

    def process_integration(integration, team)
      SyncIntegrationTeamService.sync_team integration, team
    rescue StandardError => e
      logger.error [
        "Failed to process integration #{integration.id}",
        "(provider: #{integration.provider_id}, name: #{integration.name})",
        "for team #{team.slug}",
        "- error: #{e.message} - #{e.backtrace.first}"
      ].join(' ')
    end
  end
end
