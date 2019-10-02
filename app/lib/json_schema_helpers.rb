module JsonSchemaHelpers
  # Processes a flat Hash of values, ensuring fields are converted to the data
  # type specified in the provided JsonSchema spec.
  # rubocop:disable Metrics/PerceivedComplexity
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
        elsif data[name] == '' && Array(spec.required).include?(name)
          data[name] = nil
        end
      end
    end

    data
  end
  # rubocop:enable Metrics/PerceivedComplexity

  def self.transform_additional_properties(data)
    data.each do |_key, param_value|
      next unless param_value.is_a?(Hash) && param_value.key?('additional_properties')

      param_value['additional_properties'].each do |prop|
        value = prop['value'] == '' ? nil : prop['value']
        param_value[prop['key']] = value unless prop['key'].empty?
      end
      param_value.delete 'additional_properties'
      transform_additional_properties param_value
    end
  end
end
