class ProvidersRegistry
  extend Memoist

  attr_reader :config_schemas

  def initialize(data)
    @providers, @config_schemas = prepare_and_validate!(data)
  end

  def ids
    @providers.map { |p| p['id'] }
  end
  memoize :ids

  def get(id)
    @providers.find { |p| p['id'] == id }
  end

  private

  def prepare_and_validate!(data)
    data = data.deep_dup
    config_schemas = {}

    # Must be an Array
    raise 'Providers data must be an Array' unless data.is_a?(Array)

    # Providers must have unique IDs
    ids = data.map { |p| p['id'] }.compact
    raise 'Provider IDs must be set and unique' if ids.size != data.size

    # For each provider `config_spec`:
    # - Check any custom validations for each property spec
    # - Add certain assumed JSON Schema fields
    # - Validate that each is valid JSON Schema
    # - Store the JSON Schema object
    data.each do |p|
      id = p['id']
      config_spec = p['config_spec']

      validate_property_specs config_spec['properties']

      config_spec['type'] = 'object'
      config_spec['additionalProperties'] = false

      config_schemas[id] = JsonSchema.parse!(config_spec)
    end

    [
      data.freeze,
      config_schemas.freeze
    ]
  end

  # Checks:
  # - Only allow the `overridable` flag on top level properties of types
  #   other than `array` or `object`
  # - Only allow `array`s of `object`s
  def validate_property_specs(properties)
    properties.each do |(name, property_spec)|
      type = property_spec['type']

      has_overridable_flag = property_spec.key?('overridable')
      array_or_object_type = %w[array object].include?(type)

      if has_overridable_flag && array_or_object_type
        raise [
          "'overrideable' flag can only be used on top level properties -",
          "property '#{name}' cannot have it"
        ].join(' ')
      end

      if type == 'array' && property_spec['items']['type'] != 'object'
        raise "Only arrays of objects are currently supported - property '#{name}' is an array of something else"
      end
    end
  end
end
