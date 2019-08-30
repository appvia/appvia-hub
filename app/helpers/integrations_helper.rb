module IntegrationsHelper
  def admin_integrations_path_with_selected(integration)
    resource_type = ResourceTypesService.for_provider integration.provider_id

    admin_integrations_path(
      expand: resource_type[:id],
      anchor: integration.id
    )
  end

  def delete_integration_link(integration, css_class: nil)
    if integration.resources.count.positive?
      tag.span class: css_class do
        safe_join(
          [
            'Delete (unavailable)',
            icon_with_tooltip(
              'You can only delete this integration once all resources for it are deleted',
              css_class: 'ml-2',
              style: 'color: inherit'
            )
          ]
        )
      end
    else
      link_to 'Delete',
        admin_integration_path(integration),
        method: :delete,
        class: css_class,
        data: {
          confirm: 'Are you sure you want to delete this integration permanently?',
          title: "Delete integration: #{integration.name}",
          verify: 'yes',
          verify_text: "Type 'yes' to confirm"
        },
        role: 'button'
    end
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
