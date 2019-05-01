class Integration < ApplicationRecord
  audited

  enum provider_id: PROVIDERS_REGISTRY.ids.each_with_object({}) { |id, acc| acc[id] = id }

  crypt_keeper :config,
    encryptor: :active_support,
    key: Rails.application.secrets.secret_key_base,
    salt: Rails.application.secrets.secret_salt

  before_validation :process_config

  has_many :resources,
    dependent: :restrict_with_exception,
    inverse_of: :integration

  validates :name,
    presence: true,
    uniqueness: true

  validates :provider_id, presence: true

  validates :config, presence: true

  validate :validate_config_matches_schema

  attr_readonly :provider_id

  default_value_for :config, -> { {} }

  def provider
    return if provider_id.blank?

    PROVIDERS_REGISTRY.get provider_id
  end

  def config=(hash)
    super hash.try(:to_json)
  end

  def config
    value = super
    value.present? ? JSON.parse(value) : nil
  end

  def descriptor
    name
  end

  private

  def with_config_schema
    return if provider_id.blank?

    yield PROVIDERS_REGISTRY.config_schemas[provider_id]
  end

  def process_config
    return if config.blank?

    with_config_schema do |schema|
      self.config = JsonSchemaHelpers.ensure_booleans(config, schema)
    end
  end

  def validate_config_matches_schema
    with_config_schema do |schema|
      schema.validate! config
    end
  rescue JsonSchema::AggregateError => e
    errors.add :config, e.to_s
  end
end
