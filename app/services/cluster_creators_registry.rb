class ClusterCreatorsRegistry
  extend Memoist

  OPTIONS_FIELDS = %w[init_options provision_options].freeze

  attr_reader :schemas

  def initialize(data)
    @cluster_creators, @schemas = prepare_and_validate!(data)
  end

  def all
    @cluster_creators
  end

  def ids
    @cluster_creators.map { |p| p['id'] }
  end
  memoize :ids

  def get(id)
    @cluster_creators.find { |p| p['id'] == id }
  end

  private

  def prepare_and_validate!(data)
    data = data.deep_dup
    schemas = Hash.new { |h, k| h[k] = {} }

    # Must be an Array
    raise 'Cluster creators data must be an Array' unless data.is_a?(Array)

    # Cluster creators must have unique IDs
    ids = data.map { |c| c['id'] }.compact
    raise 'Cluster creator IDs must be set and unique' if ids.size != data.size

    # Add in the data from the hub-clusters-creator gem
    gem_data = HubClustersCreator.schema.map(&:deep_stringify_keys)
    data.each do |c|
      gem_entry = gem_data.find { |e| e['id'] == c['id'] }

      raise "Missing cluster creator entry '#{c['id']}' in the hub-clusters-creator gem" if gem_entry.blank?

      # Validate that each options field is valid JSON Schema
      OPTIONS_FIELDS.each do |f|
        schemas[c['id']][f] = JsonSchema.parse! gem_entry[f]
      end

      c.merge! gem_entry
    end

    [
      data.freeze,
      schemas.freeze
    ]
  end
end
