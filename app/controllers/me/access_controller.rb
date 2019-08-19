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

      @groups = ResourceTypesService.all.map do |rt|
        integrations = ResourceTypesService.integrations_for(rt[:id]).order(:provider_id)

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
