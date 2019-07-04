module JsonSchemaHelpers
  # Processes a flat Hash of values, ensuring fields are converted to the data
  # type specified in the provided JsonSchema spec.
  def self.ensure_data_types(data, spec)
    return data if data.blank?

    spec.properties.each do |(name, property_spec)|
      case data[name]
      when Hash
        data[name] = ensure_data_types data[name], property_spec
      when Array
        data[name] = data[name].map do |item|
          ensure_data_types item, property_spec['items']
        end
      else
        if property_spec.type.include?('boolean')
          data[name] = ActiveRecord::Type::Boolean.new.cast(data[name])
        elsif property_spec.type.include?('integer')
          data[name] = data[name].to_i
        end
      end
    end

    data
  end
end
