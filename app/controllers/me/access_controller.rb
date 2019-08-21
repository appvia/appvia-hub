module Me
  class AccessController < ApplicationController
    # This controller should only ever act on the currently authenticated user,
    # so we do not need to peform any authorization checks.
    skip_authorization_check

    def show
      identities_by_integration = current_user
        .identities
        .group_by(&:integration_id)
        .transform_values(&:first)

      integrations_by_provider = current_user
        .teams
        .reduce([]) { |acc, t| acc + TeamIntegrationsService.get(t, include_dependents: true) }
        .uniq
        .group_by(&:provider_id)

      @groups = ResourceTypesService.all.map do |rt|
        integrations = rt[:providers].reduce([]) do |acc, p|
          acc + Array(integrations_by_provider[p])
        end

        entries = integrations.map do |i|
          {
            integration: i,
            identity: identities_by_integration[i.id]
          }
        end

        rt.merge entries: entries
      end
    end
  end
end
