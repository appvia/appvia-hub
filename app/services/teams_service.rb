module TeamsService
  class << self
    def create(params, current_user)
      team = Team.new params

      success = team.save

      if success
        Teams::HandleTeamCreatedWorker.perform_async team.id

        # Current user becomes an admin of the team
        TeamMembershipsService.create_or_update!(
          team: team,
          user_id: current_user.id,
          role: 'admin'
        )
      end

      [team, success]
    end

    def update(team, params)
      team.update params
    end

    def destroy!(team)
      slug = team.slug
      integration_ids = TeamIntegrationsService.get(team).map(&:id)

      team.destroy!

      Teams::HandleTeamDeletedWorker.perform_async slug, integration_ids

      team
    end
  end
end
