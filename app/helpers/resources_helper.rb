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
    when Resources::LoggingDashboard, 'Resources::LoggingDashboard', 'LoggingDashboard'
      icon 'stream'
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

  def group_resources_by_resource_type(resources)
    return [] if resources.blank?

    ResourceTypesService.all.map do |rt|
      rt.merge(
        resources: resources.select { |r| r.class.name == rt[:class] }
      )
    end
  end

  def get_service_broker_classes(classes)
    classes.collect do |c|
      id = "#{c.metadata.name}|#{c.spec.externalName}|#{c.spec.externalMetadata.displayName}"
      value = c.spec.externalMetadata.displayName
      [value, id]
    end
  end

  def get_service_broker_class_plans(plans)
    return [] if plans.nil?

    plans.collect do |p|
      id = "#{p.metadata.name}|#{p.spec.externalName}|#{p.spec.externalMetadata.displayName}"
      value = "#{p.spec.externalMetadata.displayName} - #{p.spec.description}"
      [value, id]
    end
  end
end
