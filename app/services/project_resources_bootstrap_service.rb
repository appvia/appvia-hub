class ProjectResourcesBootstrapService
  def initialize(project, resource_provisioning_service: ResourceProvisioningService.new)
    @project = project
    @resource_provisioning_service = resource_provisioning_service
  end

  def prepare_bootstrap
    return false if @project.resources.count.positive?

    project_integrations = TeamIntegrationsService.get @project.team

    ResourceTypesService.all.map do |rt|
      next nil unless rt[:top_level]

      integration = project_integrations.find do |i|
        rt[:providers].include? i.provider_id
      end

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
