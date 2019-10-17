# rubocop:disable Metrics/ModuleLength
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

  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/AbcSize
  def resource_status(resource)
    return [] if resource.status != 'active'

    agent = AgentsService.get resource.integration.provider_id, resource.integration.config

    case resource.integration.provider_id
    when 'git_hub'
      response = []
      begin
        status = agent.get_status(resource.full_name)
      rescue StandardError => e
        logger.warn "Error getting status checks from Github: #{e}"
        response << {
          colour: 'secondary',
          text: 'Status checks unavailable right now, please try refreshing the page later',
          status: 'Timeout',
          url: false
        }
      else
        status.each do |s|
          response << {
            colour: GITHUB_STATUS_TO_COLOUR[s[:state]],
            text: s[:context] + ' ' + s[:description],
            status: s[:state].capitalize,
            url: s[:target_url]
          }
        end
        response
      end
    when 'kubernetes'
      response = []
      begin
        status = agent.get_pods(resource.name)
      rescue StandardError => e
        logger.warn "Error getting pods from Kubernetes: #{e}"
        response << {
          colour: 'secondary',
          text: 'Container listings unavailable right now, please try refreshing the page later',
          status: 'Timeout',
          url: false
        }
      else
        containers = []
        status[:items].each do |pod|
          pod[:spec][:containers].each do |c|
            containers << c[:image] unless containers.include? c[:image]
          end
        end
        containers.each do |c|
          response << {
            colour: 'info',
            text: c,
            status: 'Deployed',
            url: false
          }
        end
        response
      end
    when 'quay'
      status = agent.get_repo_status(resource.name)
      items = status[:items]
      response = []
      items.each do |i|
        image_tag = i[:name]
        i[:spec][:features].each do |f|
          cves = []
          severities = []
          f[:vulnerabilities].each do |v|
            cves << v[:name]
            severities << v[:severity]
          end
          highest_severity = get_highest_severity_quay(severities)
          digest = i[:spec][:tag][:digest]
          response << {
            colour: QUAY_STATUS_TO_COLOUR[highest_severity],
            text: image_tag + ' ' + cves.join(' '),
            status: highest_severity,
            url: vuln_url(resource.name, digest)
          }
        end
      end
      response
    end
  end
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/AbcSize

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
# rubocop:enable Metrics/ModuleLength
