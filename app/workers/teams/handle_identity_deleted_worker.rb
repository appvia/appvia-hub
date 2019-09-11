module Teams
  class HandleIdentityDeletedWorker < BaseWorker
    def perform(integration_id, external_info)
      integration = Integration.find_by id: integration_id

      return if integration.nil?

      teams = TeamIntegrationsService.get_teams_for integration

      teams.each do |t|
        SyncIntegrationTeamService.remove_team_membership(
          integration,
          t.slug,
          external_info['Username']
        )
      end
    end
  end
end
