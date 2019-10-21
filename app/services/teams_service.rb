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

    # USE WITH CAUTION! See note below.
    def destroy!(team)
      slug = team.slug
      integration_ids = TeamIntegrationsService.get(team).map(&:id)

      # Delete allocations explicitly; cleanup in upstream providers should be
      # taken care of by the worker below.
      #
      # IMPORTANT: as things stand (Oct 2019) this is potentially *dangerous*
      # and could cause a "closed" integration suddenly becoming "open". Until
      # we resolve the core issue of the workflow and mutability of allocated
      # integrations, problems like this will rear it's ugly head!
      team.allocations.destroy_all

      team.destroy!

      Teams::HandleTeamDeletedWorker.perform_async slug, integration_ids

      team
    end
  end
end
