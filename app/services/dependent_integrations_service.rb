module DependentIntegrationsService
  class << self
    def potential_parents_for(provider_id)
      ResourceTypesService
        .for_provider(provider_id)
        .fetch(:depends_on, [])
        .map { |parent_provider_id| ResourceTypesService.for_provider parent_provider_id }
        .map { |resource_type| Integration.where provider_id: resource_type[:providers] }
        .flatten
        .group_by { |i| i.provider['name'] }
    end

    def find_dependent_for(integration, for_resource_type_id)
      integration.children.find do |c|
        rt = ResourceTypesService.for_integration c
        rt[:id] == for_resource_type_id
      end
    end
  end
end
