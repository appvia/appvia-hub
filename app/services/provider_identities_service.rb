module ProviderIdentitiesService
  class << self
    PROVIDERS = %w[
      git_hub
    ].freeze

    def requires_identity?(provider_id)
      PROVIDERS.include? provider_id
    end
  end
end
