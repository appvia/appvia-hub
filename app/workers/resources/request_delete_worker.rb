module Resources
  class RequestDeleteWorker < BaseWorker
    HANDLERS = {
      'Resources::CodeRepo' => {
        'git_hub' => lambda do |resource, agent, _config|
          agent.delete_repository(resource.full_name) if resource.full_name.present?
          true
        end
      },
      'Resources::DockerRepo' => {
        'quay' => lambda do |resource, agent, _config|
          agent.delete_repository(resource.name)
          true
        end,
        'ecr' => lambda do |resource, agent, _config|
          agent.delete_repository(resource.name)
          true
        end
      },
      'Resources::KubeNamespace' => {
        'kubernetes' => lambda do |resource, agent, _config|
          agent.delete_namespace(resource.name)
          true
        end
      },
      'Resources::MonitoringDashboard' => {
        'grafana' => lambda do |resource, agent, _config|
          agent.delete_dashboard resource.name
          true
        end
      },
      'Resources::LoggingDashboard' => {
        'loki' => lambda do |resource, agent, _config|
          agent.delete_logging_dashboard resource.name
          true
        end
      }
    }.freeze

    def handler_for(resource)
      HANDLERS.dig resource.type, resource.integration.provider_id
    end

    def finalise(resource)
      resource_provisioning_service = ResourceProvisioningService.new

      resource.children.each do |r|
        resource_provisioning_service.request_delete r
      end

      resource.destroy!
    end
  end
end
