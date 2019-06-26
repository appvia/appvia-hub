module EncryptedConfigHashAttribute
  extend ActiveSupport::Concern

  # Important assumptions:
  # - the presence of a db field `config` of type `text`
  # - the presence of a method `config_schema`

  included do
    crypt_keeper :config,
      encryptor: :active_support,
      key: Rails.application.secrets.secret_key_base,
      salt: Rails.application.secrets.secret_salt

    before_validation :process_config
    validate :validate_config_matches_schema

    default_value_for :config, -> { {} }
  end

  def config=(hash)
    super hash.try(:to_json)
  end

  def config
    value = super
    value.present? ? JSON.parse(value) : nil
  end

  private

  def with_config_schema
    schema = config_schema

    yield schema if schema.present?
  end

  def process_config
    return if config.blank?

    with_config_schema do |schema|
      self.config = JsonSchemaHelpers.ensure_data_types(config, schema)
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
