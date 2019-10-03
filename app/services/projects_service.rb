module ProjectsService
  class << self
    def create(params)
      project = Project.new params

      success = project.save

      Teams::HandleProjectCreatedWorker.perform_async(project.id) if success

      [project, success]
    end

    def update(project, params)
      project.update params
    end

    def destroy!(project)
      id = project.id
      slug = project.slug
      integration_ids = TeamIntegrationsService.get(project.team).map(&:id)

      project.destroy!

      Teams::HandleProjectDeletedWorker.perform_async id, slug, integration_ids

      project
    end
  end
end
