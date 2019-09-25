module Resources
  class RequestCreateWorker < BaseWorker
    HANDLERS = {
      'Resources::CodeRepo' => {
        'git_hub' => lambda do |resource, agent, config|
          Resources::CreateGitHubCodeRepoService
            .new(agent)
            .call(resource, config)

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

          provisioning_service = ResourceProvisioningService.new

          provisioning_service.request_dependent_create resource, 'MonitoringDashboard'
          provisioning_service.request_dependent_create resource, 'LoggingDashboard'

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
        'loki' => lambda do |resource, agent, _config|
          query_expression = '{namespace=\"' + resource.name + '\"}'

          result = agent.create_logging_dashboard query_expression

          resource.url = result

          true
        end
      },
      'Resources::ServiceCatalogInstance' => {
        'service_catalog' => lambda do |resource, agent, _config|
          create_parameters = resource.create_parameters.deep_dup
          JsonSchemaHelpers.transform_additional_properties create_parameters

          result = agent.create_resource(
            namespace: resource.parent.name,
            cluster_service_class_external_name: resource.class_external_name,
            cluster_service_plan_external_name: resource.plan_external_name,
            name: resource.name,
            parameters: create_parameters
          )

          resource.service_instance = result.to_hash

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
