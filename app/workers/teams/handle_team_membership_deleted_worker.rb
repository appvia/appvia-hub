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

        SyncIntegrationTeamService.remove_team_membership(
          integration,
          team_slug,
          identity.external_username
        )
      end
    end
  end
end
