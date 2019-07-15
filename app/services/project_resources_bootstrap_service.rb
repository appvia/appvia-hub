class ProjectResourcesBootstrapService
  def initialize(project, resource_provisioning_service: ResourceProvisioningService.new)
    @project = project
    @resource_provisioning_service = resource_provisioning_service
  end

  def prepare_bootstrap
    return false if @project.resources.count.positive?

    ResourceTypesService.all.map do |rt|
      next nil unless rt[:top_level]

      integration = ResourceTypesService.integrations_for(rt[:id]).first
      resource = {
        name: @project.slug,
        integration: integration
      }
      rt.merge resource: resource
    end.compact
  end

  def bootstrap(requested_by:)
    prepare_results = prepare_bootstrap

    return prepare_results if prepare_results.blank?

    return false if prepare_results.all? { |i| i[:resource][:integration].blank? }

    Audit.create!(
      action: 'project_resources_bootstrap',
      auditable: @project
    )

    prepare_results.map do |i|
      integration = i[:resource][:integration]

      next if integration.blank?

      resource = @project.send(i[:id].tableize).create!(
        integration: integration,
        requested_by: requested_by,
        name: i[:resource][:name]
      )

      @resource_provisioning_service.request_create resource

      resource
    end.compact
  end
end
