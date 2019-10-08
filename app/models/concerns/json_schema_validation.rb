module JsonSchemaValidation
  extend ActiveSupport::Concern
  # Important assumptions:
  # - the presence of methods `json_schema` and `json_data_property_name`

  included do
    before_validation :process_data
    validate :validate_data_matches_schema
  end

  def with_json_schema
    schema = json_schema

    yield schema if schema.present?
  end

  def with_data
    data = send json_data_property_name.to_s

    yield data
  end

  def process_data
    with_data do |data|
      return if data.blank?

      with_json_schema do |schema|
        send "#{json_data_property_name}=", JsonSchemaHelpers.prepare_for_schema_validation(data, schema)
      end
    end
  end

  def validate_data_matches_schema
    with_json_schema do |schema|
      with_data do |data|
        result = schema.validate data
        result.second.each do |err|
          path = err.path.reject { |p| p == '#' }.join('_').underscore.humanize
          errors.add "#{json_data_property_name} #{path}", err.message
        end
      end
    end
  end
end
