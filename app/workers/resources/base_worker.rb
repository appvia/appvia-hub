module Resources
  class BaseWorker
    include Sidekiq::Worker

    sidekiq_options queue: 'resources'

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
      agent = AgentsService.get integration.provider_id, config

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
