module JsonSchemaHelper
  def json_schema_field_help_text(property_spec)
    property_spec['pattern_text'] ||
      property_spec['examples'].try do |e|
        e = e.reject { |i| i == '' || i.nil? }.compact
        "Example(s): #{e.join(', ')}" if e.present?
      end
  end
end
