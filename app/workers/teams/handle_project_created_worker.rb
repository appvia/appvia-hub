module Teams
  class HandleProjectCreatedWorker < BaseWorker
    def perform(project_id)
      project = Project.find_by id: project_id

      return if project.nil?

      integrations = TeamIntegrationsService.get project.team

      return if integrations.blank?

      integrations.each do |i|
        process_integration i, project
      end
    end

    private

    def process_integration(integration, project)
      ProjectRobotCredentialsService.create_or_update integration, project
    rescue StandardError => e
      logger.error [
        "Failed to process integration #{integration.id}",
        "(provider: #{integration.provider_id}, name: #{integration.name})",
        "for project #{project.slug}",
        "- error: #{e.message} - #{e.backtrace.first}"
      ].join(' ')
    end
  end
end
