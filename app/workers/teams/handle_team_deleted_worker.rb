module Teams
  class HandleTeamDeletedWorker < BaseWorker
    def perform(team_slug, integration_ids)
      integration_ids.each do |id|
        integration = Integration.find_by id: id

        next if integration.nil?

        SyncIntegrationTeamService.remove_team integration, team_slug
      end
    end
  end
end
