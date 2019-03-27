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
      end
    }.freeze

    def perform(resource_id)
      with_resource(resource_id) do |resource|
        with_agent(resource.integration) do |agent|
          with_handler(resource) do |handler|
            result = handler.call resource, agent
            result ? finalise(resource) : resource.failed!
          rescue StandardError => ex
            logger.error [
              "Failed to process request for resource #{resource.id}",
              "(type: #{resource.type}, provider: #{resource.integration.provider_id})",
              "- error: #{ex.inspect}"
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

    protected

    def with_resource(id)
      resource = Resource.find_by id: id

      if resource
        yield resource
      else
        logger.error "Could not find Resource with ID: #{id}"
      end
    end

    def with_agent(integration)
      agent_initialiser = AGENT_INITIALISERS[integration.provider_id]

      agent = agent_initialiser&.call integration.config

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
  end
end
