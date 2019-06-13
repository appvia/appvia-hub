module Resources
  class RequestCreateWorker < BaseWorker
    HANDLERS = {
      'Resources::CodeRepo' => {
        'git_hub' => lambda do |resource, agent, config|
          enforce_best_practices = config['enforce_best_practices']

          result = agent.create_repository resource.name, best_practices: enforce_best_practices

          resource.private = result.private
          resource.full_name = result.full_name
          resource.url = result.html_url
          resource.enforce_best_practices = enforce_best_practices
          true
        end
      },
      'Resources::DockerRepo' => {
        'quay' => lambda do |resource, agent, _config|
          result = agent.create_repository resource.name
          resource.visibility = result.spec.visibility
          resource.base_uri = result.spec.url
          true
        end,
        'ecr' => lambda do |resource, agent, _config|
          result = agent.create_repository resource.name
          resource.visibility = result.spec.visibility
          resource.base_uri = result.spec.url
          true
        end
      },
      'Resources::KubeNamespace' => {
        'kubernetes' => lambda do |resource, agent, _config|
          agent.create_namespace resource.name

          ResourceProvisioningService.new.request_dependent_create resource, 'MonitoringDashboard'

          true
        end
      },
      'Resources::MonitoringDashboard' => {
        'grafana' => lambda do |resource, agent, config|
          template_url = config['template_url']

          result = agent.create_dashboard resource.name, template_url: template_url

          resource.url = result.url

          true
        end
      },
      'Resources::LoggingDashboard' => {
        'loki' => lambda do |resource, agent, config|
          grafana_url = config['grafana_url']
          query_expression = '{"namespace":\"' + resource.name + '\"}'

          result = agent.create_logging_dashboard resource.name, query_expression, grafana_url: grafana_url

          resource.url = result

          true
        end
      }
    }.freeze

    def handler_for(resource)
      HANDLERS.dig resource.type, resource.integration.provider_id
    end

    def finalise(resource)
      resource.status = Resource.statuses[:active]
      resource.save!
    end
  end
end
