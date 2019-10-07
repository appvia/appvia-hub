module ResourceTypesService
  class UnknownResourceType < StandardError
    attr_reader :id

    def initialize(message = nil, id: nil)
      @id = id
      super(message)
    end
  end

  class << self
    extend Memoist
    # rubocop:disable Metrics/MethodLength
    def all
      # IMPORTANT: currently we expect a 1:1 mapping between a provider ID and a
      # Resource Type - i.e. a provider can only ever be for one resource type.
      [
        {
          id: 'CodeRepo',
          class: 'Resources::CodeRepo',
          name: 'Code Repositories',
          providers: %w[git_hub].freeze,
          top_level: true
        },
        {
          id: 'DockerRepo',
          class: 'Resources::DockerRepo',
          name: 'Docker Repositories',
          providers: %w[ecr quay].freeze,
          top_level: true
        },
        {
          id: 'Operator',
          class: 'Resources::Operator',
          name: 'Operator',
          providers: %w[operator].freeze,
          top_level: true
        },
        {
          id: 'KubeNamespace',
          class: 'Resources::KubeNamespace',
          name: 'Kubernetes Namespaces',
          providers: %w[kubernetes].freeze,
          top_level: true
        },
        {
          id: 'MonitoringDashboard',
          class: 'Resources::MonitoringDashboard',
          name: 'Monitoring Dashboards',
          providers: %w[grafana].freeze,
          top_level: false,
          depends_on: %w[kubernetes].freeze
        },
        {
          id: 'LoggingDashboard',
          class: 'Resources::LoggingDashboard',
          name: 'Logging Dashboard',
          providers: %w[loki].freeze,
          top_level: false,
          depends_on: %w[kubernetes].freeze
        },
        {
          id: 'ServiceCatalogInstance',
          class: 'Resources::ServiceCatalogInstance',
          name: 'Service Catalog',
          providers: %w[service_catalog].freeze,
          top_level: false,
          depends_on: %w[kubernetes].freeze
        }
      ].map(&:freeze).freeze
    end
    # rubocop:enable Metrics/MethodLength
    memoize :all

    def get(id)
      entry = all.find { |e| e[:id] == id }

      raise UnknownResourceType.new("Unknown resource type: #{id}", id: id) if entry.blank?

      entry
    end

    def for_provider(provider_id)
      all.find { |e| e[:providers].include? provider_id }
    end

    def for_integration(integration)
      for_provider integration.provider_id
    end
  end
end
