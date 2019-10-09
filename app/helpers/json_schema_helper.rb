module JsonSchemaHelper
  def json_schema_field_help_text(property_spec)
    property_spec['pattern_text'] ||
      property_spec['examples'].try do |e|
        e = e.reject { |i| i == '' || i.nil? }.compact
        "Example(s): #{e.join(', ')}" if e.present?
      end
  end

  def json_schema_string_select_list(property_spec)
    options = property_spec['oneOf'].map { |o| [o['title'], o['enum']&.first || o['title']] } if property_spec['oneOf'].present?
    options = property_spec['enum'].map { |o| [o, o] } if property_spec['enum'].present?
    options
  end

  def json_schema_process_for_display(data)
    JsonSchemaHelpers.transform_additional_properties data
  end
end
