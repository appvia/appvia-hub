class Integration < ApplicationRecord
  include EncryptedConfigHashAttribute

  audited

  enum provider_id: PROVIDERS_REGISTRY.ids.each_with_object({}) { |id, acc| acc[id] = id }

  validates :name,
    presence: true,
    uniqueness: true

  validates :provider_id, presence: true

  validates :config, presence: true

  attr_readonly :provider_id

  has_many :resources,
    dependent: :restrict_with_exception,
    inverse_of: :integration

  has_many :user_identities,
    class_name: 'Identity',
    dependent: :restrict_with_exception,
    inverse_of: :integration

  def provider
    return if provider_id.blank?

    PROVIDERS_REGISTRY.get provider_id
  end

  def config_schema
    return nil if provider_id.blank?

    schema = PROVIDERS_REGISTRY.config_schemas[provider_id]

    raise "Missing config schema for provider '#{provider_id}'" if schema.blank?

    schema
  end

  def descriptor
    name
  end
end
