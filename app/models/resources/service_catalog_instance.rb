module Resources
  class ServiceCatalogInstance < Resource
    include JsonSchemaValidation

    attr_accessor :create_parameters_json_schema

    attr_json :class_name, :string
    attr_json :class_external_name, :string
    attr_json :class_display_name, :string

    attr_json :plan_name, :string
    attr_json :plan_external_name, :string
    attr_json :plan_display_name, :string

    attr_json :create_parameters, ActiveModel::Type::Value.new
    attr_json :service_instance, ActiveModel::Type::Value.new

    # Can only ever be "attached" to another resource
    validates :parent_id, presence: true

    validates :class_name, presence: true
    validates :class_external_name, presence: true
    validates :class_display_name, presence: true

    validates :plan_name, presence: true
    validates :plan_external_name, presence: true
    validates :plan_display_name, presence: true

    def json_schema
      create_parameters_json_schema
    end

    def json_data_property_name
      :create_parameters
    end
  end
end
