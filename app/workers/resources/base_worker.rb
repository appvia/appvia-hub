# rubocop:disable Metrics/ClassLength
module Resources
  class BaseWorker
    include Sidekiq::Worker

    AGENT_INITIALISERS = {
      'git_hub' => lambda do |config|
        GitHubAgent.new(
          app_id: config['app_id'],
          app_private_key: config['app_private_key'],
          app_installation_id: config['app_installation_id'],
          org: config['org']
        )
      end,
      'ecr' => lambda do |config|
        ECRAgent.new(
          agent_base_url: Rails.configuration.agents.ecr.base_url,
          agent_token: Rails.configuration.agents.ecr.token,
          org: config['org'],
          access_id: config['access_id'],
          access_token: config['access_token'],
          region: config['region'],
          account: config['account'],
          global_robot_name: config['global_robot_name']
        )
      end,
      'quay' => lambda do |config|
        QuayAgent.new(
          agent_base_url: Rails.configuration.agents.quay.base_url,
          agent_token: Rails.configuration.agents.quay.token,
          quay_access_token: config['api_access_token'],
          org: config['org'],
          global_robot_name: config['global_robot_name']
        )
      end,
      'kubernetes' => lambda do |config|
        KubernetesAgent.new(
          agent_base_url: Rails.configuration.agents.kubernetes.base_url,
          agent_token: Rails.configuration.agents.kubernetes.token,
          kube_api_url: config['api_url'],
          kube_ca_cert: config['ca_cert'],
          kube_token: config['token'],
          global_service_account_name: config['global_service_account_name']
        )
      end,
      'grafana' => lambda do |config|
        GrafanaAgent.new(
          agent_base_url: Rails.configuration.agents.grafana.base_url,
          agent_token: Rails.configuration.agents.grafana.token,
          grafana_url: config['url'],
          grafana_api_key: config['api_key'],
          grafana_ca_cert: config['ca_cert']
        )
      end,
      'loki' => lambda do |config|
        LokiAgent.new(
          grafana_url: config['grafana_url']
        )
      end
    }.freeze

    def perform(resource_id)
      with_resource(resource_id) do |resource|
        config = config_for resource.integration, resource.project

        with_agent(resource.integration, config) do |agent|
          with_handler(resource) do |handler|
            result = handler.call resource, agent, config
            result ? finalise(resource) : resource.failed!
          rescue StandardError => e
            logger.error [
              "Failed to process request for resource #{resource.id}",
              "(type: #{resource.type}, provider: #{resource.integration.provider_id})",
              "- error: #{e.inspect}"
            ].join(' ')

            resource.failed!
          end
        end
      end
    end

    def handler_for(_resource)
      raise NotImplementedError
    end

    def finalise(_resource)
      raise NotImplementedError
    end

    private

    def with_resource(id)
      resource = Resource.find_by id: id

      if resource
        yield resource
      else
        logger.error "Could not find Resource with ID: #{id}"
      end
    end

    def with_agent(integration, config)
      agent_initialiser = AGENT_INITIALISERS[integration.provider_id]

      agent = agent_initialiser&.call config

      if agent
        yield agent
      else
        logger.error "No agent available for provider: #{integration.provider_id} (ID: #{integration.id})"
      end
    end

    def with_handler(resource)
      handler = handler_for resource

      if handler
        yield handler
      else
        logger.error "No handler found for resource type: #{resource.type}, provider: #{resource.integration.provider_id}"
      end
    end

    def config_for(integration, project)
      IntegrationOverridesService.new.effective_config_for integration, project
    end
  end
end
# rubocop:enable Metrics/ClassLength
