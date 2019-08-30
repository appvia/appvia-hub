PROVIDERS_REGISTRY = ProvidersRegistry.new(
  YAML.safe_load(
    Rails.root.join('config', 'providers.yml').read
  )
)

CLUSTER_CREATORS_REGISTRY = ClusterCreatorsRegistry.new(
  YAML.safe_load(
    Rails.root.join('config', 'cluster_creators.yml').read
  )
)
