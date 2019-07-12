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
    resource_type = ResourceTypesService.get resource_type_id
    integrations = ResourceTypesService.integrations_for(resource_type[:id])

    return if integrations.empty?

    resource_class = resource_type[:class].constantize
    dependent_resource = resource_class.create!(
      integration: integrations.first,
      requested_by: parent_resource.requested_by,
      parent: parent_resource,
      project: parent_resource.project,
      name: parent_resource.name
    )
    request_create dependent_resource
  end
end
