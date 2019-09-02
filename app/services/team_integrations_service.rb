module TeamIntegrationsService
  class << self
    def get(team, include_dependents: false)
      # Assumption: dependent integrations are never allocated, so will only ever
      # be in the pool of unallocated (thus requiring checking their parents instead).

      integrations = [
        Integration.unallocated.entries,
        team.integrations
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
  end
end
