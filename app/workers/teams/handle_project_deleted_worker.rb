module Teams
  class HandleProjectDeletedWorker < BaseWorker
    def perform(project_id, project_slug, integration_ids)
      integration_ids.each do |id|
        integration = Integration.find_by id: id

        next if integration.nil?

        process_integration(
          integration,
          project_id,
          project_slug
        )
      end
    end

    private

    def process_integration(integration, project_id, project_slug)
      ProjectRobotCredentialsService.remove integration, project_id, project_slug
    rescue StandardError => e
      logger.error [
        "Failed to process integration #{integration.id}",
        "(provider: #{integration.provider_id}, name: #{integration.name})",
        "for project #{project_slug}",
        "- error: #{e.message} - #{e.backtrace.first}"
      ].join(' ')
    end
  end
end
