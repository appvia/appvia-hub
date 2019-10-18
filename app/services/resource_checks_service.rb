class ResourceChecksService
  GITHUB_STATUS_TO_COLOUR = {
    'pending' => 'warning',
    'success' => 'success',
    'failure' => 'danger'
  }.freeze

  def get_checks(resource)
    config = IntegrationOverridesService.new.effective_config_for resource.integration, resource.project
    agent = AgentsService.get resource.integration.provider_id, config

    case resource.integration.provider_id
    when 'git_hub'
      git_hub_checks resource, agent
    when 'kubernetes'
      kubernetes_checks resource, agent
    end
  end

  private

  def git_hub_checks(resource, agent)
    response = []
    status = agent.get_status(resource.full_name)
  rescue StandardError => e
    Rails.logger.warn "Error getting status checks from Github: #{e}"
    response << {
      colour: 'secondary',
      text: 'Status checks unavailable right now.',
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

  def kubernetes_checks(resource, agent)
    response = []
    status = agent.get_pods(resource.name)
  rescue StandardError => e
    Rails.logger.warn "Error getting pods from Kubernetes: #{e}"
    response << {
      colour: 'secondary',
      text: 'Container listings unavailable right now.',
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
end
