module TeamIntegrationsService
  class << self
    def get(team, include_dependents: false)
      # Assumption: dependent integrations are never allocated, so will only ever
      # be in the pool of unallocated (thus requiring checking their parents instead).

      integrations = [
        Integration.unallocated.entries,
        team.integrations.entries
      ].flatten

      integrations
        .select do |i|
          if include_dependents
            if i.parents.blank?
              true
            else
              i.parents.any? { |p| integrations.include?(p) }
            end
          else
            ResourceTypesService.for_provider(i.provider_id)[:top_level]
          end
        end
        .sort_by(&:name)
    end

    def for_user(user)
      user
        .teams
        .reduce([]) do |acc, t|
          acc + TeamIntegrationsService.get(t, include_dependents: true)
        end
        .uniq
        .sort_by(&:name)
    end

    def get_teams_for(integration)
      integrations_to_check = integration.parents.presence || [integration]

      if integrations_to_check.any? { |i| i.allocations.size.zero? }
        Team.all.entries
      else
        integrations_to_check
          .map(&:teams)
          .flatten
          .uniq
      end
    end

    def bifurcate_teams(teams, for_integration)
      all_allowed_teams = TeamIntegrationsService.get_teams_for for_integration

      allowed, not_allowed = teams.sort_by(&:name).partition do |t|
        all_allowed_teams.include? t
      end

      {
        allowed: allowed,
        not_allowed: not_allowed
      }
    end
  end
end
