module ProjectRobotCredentialsService
  PREFIX = 'hub-'.freeze

  class << self
    def build_name(slug)
      "#{PREFIX}space-robot-#{slug}"
    end

    def get(integration_id, project_id, project_slug)
      name = build_name project_slug

      Credential
        .robot
        .by_integration(integration_id)
        .by_owner(Project.name, project_id)
        .by_name(name)
        .first
    end

    def create_or_update(integration, project)
      name = build_name project.slug
      description = "Robot token for space #{project.slug}. Automatically managed by the hub."

      result = case integration.provider_id
               when 'quay'
                 agent = agent_for integration

                 result = agent.create_robot_token name, description

                 { value: result.spec.token }
               when 'kubernetes'
                 agent = agent_for integration

                 result = agent.create_service_account name

                 { value: result.spec.token }
               end

      return if result.blank?

      credential = get integration.id, project.id, project.slug

      # Some providers allow cycling/refreshing of tokens/credentials, so if we
      # have a value here use it to update an existing credential (if present).

      credential.update!(value: result[:value]) if result[:value].present? && credential.present?

      return credential if credential.present?

      # ... otherwise we expect a brand new robot token and need to capture it
      # in a new Credential record in the db.

      if result[:value].blank?
        raise [
          'Expected a new robot token from agent but got a blank value -',
          "integration ID: #{integration.id}, provider: #{integration.provider_id}"
        ].join(' ')
      end

      project.credentials.robot.create!(
        integration: integration,
        name: name,
        value: result[:value]
      )
    end

    def remove(integration, project_id, project_slug)
      name = build_name project_slug

      case integration.provider_id
      when 'quay'
        agent = agent_for integration

        agent.delete_robot_token name
      when 'kubernetes'
        agent = agent_for integration

        agent.delete_service_account name
      end

      # Credential records for the project may have been destroyed as part of a
      # Project destroy, but let's check and clean up in case not...

      credential = get integration.id, project_id, project_slug

      return if credential.blank?

      credential.destroy!

      true
    end

    private

    def agent_for(integration)
      AgentsService.get integration.provider_id, integration.config
    end
  end
end
