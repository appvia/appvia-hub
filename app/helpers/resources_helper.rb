module ResourcesHelper
  RESOURCE_STATUS_TO_CLASS = {
    'pending' => 'secondary',
    'active' => 'success',
    'deleting' => 'warning',
    'failed' => 'danger'
  }.freeze

  def resource_icon(resource_class_or_name = nil)
    case resource_class_or_name
    when Resources::CodeRepo, 'Resources::CodeRepo', 'CodeRepo'
      icon 'code'
    when Resources::DockerRepo, 'Resources::DockerRepo', 'DockerRepo'
      brand_icon 'docker'
    when Resources::KubeNamespace, 'Resources::KubeNamespace', 'KubeNamespace'
      icon 'cloud'
    when Resources::MonitoringDashboard, 'Resources::MonitoringDashboard', 'MonitoringDashboard'
      icon 'tachometer-alt'
    else
      icon 'cogs'
    end
  end

  def resource_status_badge(status, css_class: [])
    tag.span status,
      class: [
        'badge',
        "badge-#{RESOURCE_STATUS_TO_CLASS[status]}",
        'text-capitalize'
      ] + Array(css_class)
  end

  def delete_resource_link(project_id, resource, css_class: [])
    link_to 'Delete',
      project_resource_path(project_id, resource),
      method: :delete,
      class: Array(css_class),
      data: {
        confirm: 'Are you sure you want to delete this resource permanently?',
        title: "Request deletion for resource: #{resource.descriptor}",
        verify: resource.name,
        verify_text: "Type '#{resource.name}' to confirm"
      },
      role: 'button'
  end

  def global_credentials_for(resource)
    config = resource.integration.config
    case resource
    when Resources::DockerRepo
      case resource.integration.provider_id
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
    when Resources::KubeNamespace
      case resource.integration.provider_id
      when 'kubernetes'
        {
          'Kube API' => config['api_url'],
          'CA cert' => config['ca_cert'],
          'Token' => config['global_service_account_token']
        }
      end
    end
  end

  def group_resources_by_resource_type(resources)
    return [] if resources.blank?

    ResourceTypesService.all.map do |rt|
      rt.merge(
        resources: resources.select { |r| r.class.name == rt[:class] }
      )
    end
  end
end
