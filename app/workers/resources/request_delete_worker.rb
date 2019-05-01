module Resources
  class RequestDeleteWorker < BaseWorker
    HANDLERS = {
      'Resources::CodeRepo' => {
        'git_hub' => lambda do |resource, agent|
          agent.delete_repository(resource.full_name) if resource.full_name.present?
          true
        end
      },
      'Resources::DockerRepo' => {
        'quay' => lambda do |resource, agent|
          agent.delete_repository(resource.name)
          true
        end
      },
      'Resources::KubeNamespace' => {
        'kubernetes' => lambda do |resource, agent|
          agent.delete_namespace(resource.name)
          true
        end
      }
    }.freeze

    def handler_for(resource)
      HANDLERS.dig resource.type, resource.integration.provider_id
    end

    def finalise(resource)
      resource.destroy!
    end
  end
end
