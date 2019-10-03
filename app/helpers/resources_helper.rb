module ResourcesHelper
  RESOURCE_STATUS_TO_CLASS = {
    'pending' => 'secondary',
    'active' => 'success',
    'deleting' => 'warning',
    'failed' => 'danger'
  }.freeze
  GITHUB_STATUS_TO_COLOUR = {
    'pending' => 'warning',
    'success' => 'success',
    'failure' => 'danger'
  }.freeze
  QUAY_STATUS_TO_COLOUR = {
    'High' => 'danger',
    'Medium' => 'warning',
    'Low' => 'info',
    'Negligible' => 'secondary',
    'Unknown' => 'secondary'
  }.freeze
  GRAFANA_STATUS_TO_COLOUR = {
    'ALL' => 'info',
    'no_data' => 'warning',
    'paused' => 'info',
    'pending' => 'info',
    'alerting' => 'danger',
    'ok' => 'success'
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

  def resource_status(resource)
    agent = AgentsService.get resource.integration.provider_id, resource.integration.config

    case resource.integration.provider_id
    when 'git_hub'
      status = agent.get_status(resource.name)
      response = []
      status.each do |s|
        response << {
          colour: GITHUB_STATUS_TO_COLOUR[s[:state]],
          text: s[:context] + ' ' + s[:description],
          status: s[:state],
          url: s[:target_url]
        }
      end
      response
    when 'kubernetes'
      status = agent.get_all_deployed_versions(resource.name)
      response = []
      status.each do |s|
        response << {
          colour: 'info',
          text: s,
          status: 'Deployed',
          url: false
        }
      end
      response
    end
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
end
