module Teams
  class HandleIntegrationTeamsUpdateWorker < BaseWorker
    def perform(integration_id, teams_added_ids, teams_removed_slugs)
      integration = Integration.find_by id: integration_id

      return if integration.nil?

      teams_added_ids.each do |id|
        team = Team.find_by id: id

        next if team.nil?

        SyncIntegrationTeamService.sync_team integration, team
      end

      teams_removed_slugs.each do |slug|
        SyncIntegrationTeamService.remove_team integration, slug
      end
    end
  end
end
