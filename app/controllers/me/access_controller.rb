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

      users_integrations = TeamIntegrationsService.for_user current_user
      integrations_by_provider = users_integrations.group_by(&:provider_id)

      project_ids = current_user
        .teams
        .map(&:project_ids)
        .flatten
      project_robot_credentials_by_integration = ProjectRobotCredentialsService
        .for_projects(project_ids)
        .group_by(&:integration_id)

      @groups = build_groups(
        integrations_by_provider,
        identities_by_integration,
        project_robot_credentials_by_integration
      )

      users_integrations_ids = users_integrations.map(&:id)
      @unused_identities = identities_by_integration.reject do |integration_id, _|
        users_integrations_ids.include? integration_id
      end.values

      @unmask = params.key? 'unmask'
    end

    private

    def build_groups(integrations_by_provider, identities_by_integration, project_robot_credentials_by_integration)
      ResourceTypesService.all.map do |rt|
        integrations = rt[:providers].reduce([]) do |acc, p|
          acc + Array(integrations_by_provider[p])
        end

        entries = integrations.map do |i|
          {
            integration: i,
            identity: identities_by_integration[i.id],
            project_robot_credentials: Array(project_robot_credentials_by_integration[i.id])
          }
        end

        rt.merge entries: entries
      end
    end
  end
end
