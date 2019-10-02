module Resources
  class ServiceCatalogInstance < Resource
    attr_json :class_name, :string
    attr_json :class_external_name, :string
    attr_json :class_display_name, :string

    attr_json :plan_name, :string
    attr_json :plan_external_name, :string
    attr_json :plan_display_name, :string

    attr_json :create_parameters, ActiveModel::Type::Value.new
    attr_json :create_parameters_schema, ActiveModel::Type::Value.new
    attr_json :service_instance, ActiveModel::Type::Value.new

    # Can only ever be "attached" to another resource
    validates :parent_id, presence: true

    validates :class_name, presence: true
    validates :class_external_name, presence: true
    validates :class_display_name, presence: true

    validates :plan_name, presence: true
    validates :plan_external_name, presence: true
    validates :plan_display_name, presence: true

    validate :json_schema_validation

    private

    def json_schema_validation
      return if create_parameters_schema.nil?

      to_validate = JsonSchemaHelpers.ensure_data_types create_parameters.to_hash, create_parameters_schema
      result = create_parameters_schema.validate JsonSchemaHelpers.transform_additional_properties to_validate

      result.second.each do |err|
        path = err.path.reject { |p| p == '#' }.join('.').underscore.humanize
        errors.add path, err.message
      end
    end
  end
end
