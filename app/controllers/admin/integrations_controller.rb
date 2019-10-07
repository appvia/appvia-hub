module Admin
  # rubocop:disable Metrics/ClassLength
  class IntegrationsController < BaseController
    before_action :find_integration, only: %i[edit update]
    before_action :find_subscription_integration, only: %i[list_subscriptions show_subscription approve_subscription]

    authorize_resource

    # GET /admin/integrations
    def index
      integrations_by_provider = Integration.all.group_by(&:provider_id)

      @group_to_expand = params[:expand]
      @unmask = params.key? 'unmask'

      @agents = AgentsService
      @groups = ResourceTypesService.all.map do |rt|
        providers = rt[:providers].map do |provider_id|
          {
            definition: PROVIDERS_REGISTRY.get(provider_id),
            integrations: Array(integrations_by_provider[provider_id])
          }
        end

        rt.merge providers: providers
      end
    end

    # GET /admin/integrations/new
    def new
      provider_id = params.require(:provider_id)

      unprocessable_entity_error && return unless Integration.provider_ids.key?(provider_id)

      @potential_parents = find_potential_parents provider_id

      if !ResourceTypesService.for_provider(provider_id)[:top_level] &&
         @potential_parents.blank?
        alert = 'Unable to create a new integration for the specified provider, as no parent integrations are available yet for it.'
        redirect_to root_path, alert: alert
      end

      @potential_teams = find_potential_teams provider_id

      @integration = Integration.new provider_id: provider_id
    end

    # GET /admin/integrations/:id/edit
    def edit
      @potential_parents = find_potential_parents @integration.provider_id
      @potential_teams = find_potential_teams @integration.provider_id
    end

    # GET /admin/integrations/:integration_id/operators/:id/subscriptions/:namespace/:name/approve
    def approve_subscription
      name = params[:name]
      namespace = params[:namespace]

      # approve the subscription
      @agent.approve_subscription(namespace, name)

      # invalidate the cache
      Rails.cache.delete(params[:integration_id])

      redirect_to admin_integration_operators_subscriptions_path(@integration), notice: 'Upgrade has been approved'
    end

    # GET /admin/integrations/:integration_id/operators/:id/subscriptions
    def list_subscriptions
      cache_key = params[:integration_id].to_s

      unless Rails.cache.exist?(cache_key, expires_in: 5.minutes)
        @subscriptions = @agent.list_subscriptions_updates unless Rails.cache.exist?(cache_key)

        Rails.cache.write(cache_key, @subscriptions)
      end

      @subscriptions = Rails.cache.read(cache_key)
    end

    # GET /admin/integrations/:integration_id/operators/:id/subscriptions/:namespace/:name
    def show_subscription
      name = params[:name]
      namespace = params[:namespace]

      subscription = @agent.get_subscription(namespace, name)
      raise ArgumentError, "subscription does not exist, name: #{namespace}/#{name}" if subscription.nil?

      package = @agent.get_package(
        subscription.spec.name,
        subscription.spec.source
      )
      channel = @agent.get_package_by_channel(
        subscription.spec.name,
        subscription.spec.source,
        subscription.spec.channel
      )

      render locals: {
        catalog: generate_catalog_model(package, subscription),
        channel: channel,
        info: generate_package_model(package, channel, subscription),
        package: package,
        subscription: generate_subscription_model(subscription)
      }
    end

    # POST /admin/integrations
    def create
      params = integration_params

      params[:parent_ids].reject!(&:blank?) if params.key?(:parent_ids)
      params[:team_ids].reject!(&:blank?) if params.key?(:team_ids)

      @integration, success = Admin::IntegrationsService.create params

      if success
        path = helpers.admin_integrations_path_with_selected @integration
        redirect_to path, notice: 'New integration was successfully created.'
      else
        @potential_parents = find_potential_parents @integration.provider_id
        @potential_teams = find_potential_teams @integration.provider_id
        render :new
      end
    end

    # PATCH/PUT /admin/integrations/:id
    def update
      params = integration_params

      params[:parent_ids].reject!(&:blank?) if params.key?(:parent_ids)
      params[:team_ids].reject!(&:blank?) if params.key?(:team_ids)

      if Admin::IntegrationsService.update(@integration, params)
        path = helpers.admin_integrations_path_with_selected @integration
        redirect_to path, notice: 'Integration was successfully updated.'
      else
        @potential_parents = find_potential_parents @integration.provider_id
        @potential_teams = find_potential_teams @integration.provider_id
        render :edit
      end
    end

    private

    def find_integration
      @integration = Integration.find params[:id]
    end

    def find_subscription_integration
      @integration ||= Integration.find params[:integration_id]
      @agent = AgentsService.get('operator', @integration.config)
    end

    def find_potential_parents(provider_id)
      DependentIntegrationsService.potential_parents_for provider_id
    end

    def find_potential_teams(provider_id)
      if ResourceTypesService.for_provider(provider_id)[:top_level]
        Team.all.entries
      else
        []
      end
    end

    def integration_params
      params.require(:integration).permit(:provider_id, :name, parent_ids: [], config: {}, team_ids: [])
    end

    # generate_package_model generates a model
    # rubocop:disable Lint/HandleExceptions,Metrics/MethodLength,Metrics/AbcSize
    def generate_package_model(package, channel, subscription)
      model = {
        capabilibilities: extract { channel.annotations.capabilities.downcase },
        categories: extract { channel.annotations.categories.downcase },
        certified: extract('false') { channel.annotations.certified },
        channel_name: extract { subscription.spec.channel },
        crds: [],
        full_description: extract('') { channel.description },
        name: extract('') { package.status.packageName },
        package_display_name: extract { channel.displayName },
        provider: extract('') { package.status.provider.name },
        repository: extract { channel.annotations.repository },
        short_description: extract('') { channel.annotations.description },
        upgradable: false,
        usage: {},
        version: @agent.parse_version(extract { subscription.status.installedCSV })
      }

      # do we have provider details
      state = extract { subscription.status.state.downcase }
      if state == 'upgradepending'
        model[:upgradable] = true
        model[:upgrade_version] = @agent.parse_version(extract { subscription.status.currentCSV })
      end

      model[:icon] = extract { channel.icon.first.base64data } if extract(false) { channel.icon.first.mediatype } == 'image/svg+xml'

      # do we have any own crds?
      crds = extract([]) { channel.customresourcedefinitions.owned }
      crds.each do |x|
        model[:crds].push(
          description: x.description,
          display_name: x.displayName,
          kind: x.kind,
          name: x.name,
          version: x.version
        )
      end

      # do we have examples?
      data = extract('[]') { channel.annotations['alm-examples'] }
      begin
        JSON.parse(data).each do |x|
          model[:usage][x['kind']] = x.to_yaml
        end
      rescue StandardError => _e; end
      model
    end
    # rubocop:enable Lint/HandleExceptions,Metrics/MethodLength,Metrics/AbcSize

    # generate_subscription_model creates a model for the subscription
    def generate_subscription_model(subscription)
      model = {
        approvals: extract { subscription.spec.installPlanApproval.downcase },
        name: subscription.metadata.name,
        namespace: subscription.metadata.namespace,
        installplan: extract { subscription.status.installplan.name },
        running: 'unknown'
      }
      # check if the pod is running
      state = extract('') { subscription.status.state.downcase }
      model[:running] = 'running' if %w[atlatestknown upgradepending].include?(state)

      model
    end

    # extract is a helper method to aid in extracting values from the resource
    # rubocop:disable Lint/RescueException,Lint/HandleExceptions
    def extract(default_value = 'unknown', &block)
      begin
        value = yield block
        unless value.nil?
          return value unless value.class == String.class
          return value unless value.empty?
        end
      rescue Exception => _e; end
      default_value
    end
    # rubocop:enable Lint/RescueException,Lint/HandleExceptions

    # generate_catalog_model creates a model for the catalog
    def generate_catalog_model(package, subscription)
      catalog = {
        display_name: extract { package.status.catalogSourceDisplayName },
        healthy: true,
        namespace: extract { package.status.catalogSourceNamespace },
        publisher: extract { package.status.catalogSourcePublisher },
        source: extract { package.status.catalogSource }
      }

      status = subscription.status
      return catalog if status.nil?

      (extract([]) { status.catalogHealth }).each do |x|
        next unless extract { x.catalogSourceRef.name } == subscription.spec.source

        catalog[:healthy] = extract(false) { x.healthy }
        catalog[:last_sync] = extract { x.lastUpdated }
      end

      catalog
    end
  end
  # rubocop:enable Metrics/ClassLength
end
