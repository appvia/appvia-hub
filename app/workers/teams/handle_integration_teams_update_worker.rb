module Teams
  class HandleIntegrationTeamsUpdateWorker < BaseWorker
    def perform(integration_id, teams_added_ids, teams_removed_slugs)
      integration = Integration.find_by id: integration_id

      return if integration.nil?

      teams_added_ids.each do |id|
        team = Team.find_by id: id

        next if team.nil?

        process_team_added integration, team
      end

      teams_removed_slugs.each do |slug|
        process_team_removed integration, slug
      end
    end

    private

    def process_team_added(integration, team)
      SyncIntegrationTeamService.sync_team integration, team

      team.projects.each do |p|
        ProjectRobotCredentialsService.create_or_update integration, p
      end
    rescue StandardError => e
      logger.error [
        "Failed to process integration #{integration.id}",
        "(provider: #{integration.provider_id}, name: #{integration.name})",
        "for team #{team.slug}",
        "- error: #{e.message} - #{e.backtrace.first}"
      ].join(' ')
    end

    def process_team_removed(integration, team_slug)
      SyncIntegrationTeamService.remove_team integration, team_slug

      team = Team.friendly.find team_slug

      team.projects.each do |p|
        ProjectRobotCredentialsService.remove(
          integration,
          p.id,
          p.slug
        )
      end
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
