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
      [
        {
          id: 'CodeRepo',
          class: 'Resources::CodeRepo',
          name: 'Code Repositories',
          top_level: true,
          providers: %w[git_hub].freeze
        },
        {
          id: 'DockerRepo',
          class: 'Resources::DockerRepo',
          name: 'Docker Repositories',
          top_level: true,
          providers: %w[ecr quay].freeze
        },
        {
          id: 'KubeNamespace',
          class: 'Resources::KubeNamespace',
          name: 'Kubernetes Namespaces',
          top_level: true,
          providers: %w[kubernetes].freeze
        },
        {
          id: 'MonitoringDashboard',
          class: 'Resources::MonitoringDashboard',
          name: 'Monitoring Dashboards',
          top_level: false,
          providers: %w[grafana].freeze
        },
        {
          id: 'LoggingDashboard',
          class: 'Resources::LoggingDashboard',
          name: 'Logging Dashboard',
          top_level: false,
          providers: %w[loki].freeze
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

    def integrations_for(id)
      entry = get id

      Integration
        .where(provider_id: entry[:providers])
        .order(:created_at)
    end
  end
end
