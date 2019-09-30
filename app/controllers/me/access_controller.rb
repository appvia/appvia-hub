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

      integrations_by_provider = TeamIntegrationsService
        .for_user(current_user)
        .group_by(&:provider_id)

      project_ids = current_user
        .teams
        .map(&:project_ids)
        .flatten
      project_robot_credentials_by_integration = ProjectRobotCredentialsService
        .for_projects(project_ids)
        .group_by(&:integration_id)

      @groups = ResourceTypesService.all.map do |rt|
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

      @unmask = params.key? 'unmask'
    end
  end
end
