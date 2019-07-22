class ResourceProvisioningService
  def request_create(resource)
    Resources::RequestCreateWorker.perform_async resource.id

    Audit.create!(
      action: 'request_create',
      auditable: resource,
      associated: resource.project
    )

    true
  end

  def request_delete(resource)
    resource.deleting!

    Resources::RequestDeleteWorker.perform_async resource.id

    Audit.create!(
      action: 'request_delete',
      auditable: resource,
      associated: resource.project
    )

    true
  end

  def request_dependent_create(parent_resource, resource_type_id)
    dependent_integration = DependentIntegrationsService.find_dependent_for(
      parent_resource.integration,
      resource_type_id
    )

    return if dependent_integration.blank?

    resource_type = ResourceTypesService.get resource_type_id
    resource_class = resource_type[:class].constantize
    dependent_resource = resource_class.create!(
      integration: dependent_integration,
      requested_by: parent_resource.requested_by,
      parent: parent_resource,
      project: parent_resource.project,
      name: parent_resource.name
    )
    request_create dependent_resource
  end
end
