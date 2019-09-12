module Teams
  class HandleTeamCreatedWorker < BaseWorker
    def perform(team_id)
      team = Team.find_by id: team_id

      return if team.nil?

      integrations = TeamIntegrationsService.get team

      return if integrations.blank?

      integrations.each do |i|
        SyncIntegrationTeamService.sync_team i, team
      end
    end
  end
end
