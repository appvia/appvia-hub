module Teams
  class HandleIdentityCreatedWorker < BaseWorker
    def perform(identity_id)
      identity = Identity.find_by id: identity_id

      return if identity.nil?

      integration = identity.integration

      teams = TeamIntegrationsService.get_teams_for integration

      teams.each do |t|
        membership = t.memberships.find_by user_id: identity.user_id

        next if membership.nil?

        SyncIntegrationTeamService.sync_team_membership integration, membership
      end
    end
  end
end
