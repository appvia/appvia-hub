module IntegrationsHelper
  def admin_integrations_path_with_selected(integration)
    resource_type = ResourceTypesService.for_provider integration.provider_id

    admin_integrations_path(
      expand: resource_type[:id],
      anchor: integration.id
    )
  end

  def config_field_title(name, spec)
    if spec
      spec['title']
    else
      name.humanize
    end
  end

  def global_credentials_for(integration)
    config = integration.config
    provider_id = integration.provider_id
    resource_type = ResourceTypesService.for_integration integration

    case resource_type[:id]
    when 'DockerRepo'
      case provider_id
      when 'ecr'
        {
          'Robot Username' => config['global_robot_name'],
          'Robot Access ID' => config['global_robot_access_id'],
          'Robot Secret' => config['global_robot_token']
        }
      end
    end
  end
end
