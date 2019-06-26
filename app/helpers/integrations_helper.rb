module IntegrationsHelper
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
      when 'quay'
        {
          'Robot name' => config['global_robot_name'],
          'Robot token' => config['global_robot_token']
        }
      when 'ecr'
        {
          'Robot Username' => config['global_robot_name'],
          'Robot Access ID' => config['global_robot_access_id'],
          'Robot Secret' => config['global_robot_token']
        }
      end
    when 'KubeNamespace'
      case provider_id
      when 'kubernetes'
        {
          'Kube API' => config['api_url'],
          'CA cert' => config['ca_cert'],
          'Token' => config['global_service_account_token']
        }
      end
    end
  end
end
