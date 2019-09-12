module IdentitiesService
  class << self
    def create!(relation, params)
      identity = relation.create! params

      Teams::HandleIdentityCreatedWorker.perform_async identity.id

      identity
    end

    def update!(identity, params)
      identity.update! params

      identity
    end

    def destroy!(identity)
      integration = identity.integration
      external_info = identity.external_info

      identity.destroy!

      Teams::HandleIdentityDeletedWorker.perform_async(
        integration.id,
        external_info
      )

      identity
    end
  end
end
