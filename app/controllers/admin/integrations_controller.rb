module Admin
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

      redirect_to admin_integration_operators_subscriptions_path(@integration), notice: 'Upgrade has been approved'
    end

    # GET /admin/integrations/:integration_id/operators/:id/subscriptions
    def list_subscriptions
      @subscriptions = @agent.list_subscriptions_updates
    end

    # GET /admin/integrations/:integration_id/operators/:id/subscriptions/:namespace/:name
    def show_subscription
      subscription = @agent.get_subscription(params[:namespace], params[:name])
      if subscription.nil?
        raise ArgumentError, "subscription does not exist, name: #{params[:name]}/#{params[:namespace]}"
      end

      package = @agent.get_package(subscription.spec.name, subscription.spec.source)
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
        subscription: generate_subscription_model(subscription),
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

    def unknown(value, default_value = 'unknown', downcase = true)
      return default_value if value.nil? || value.empty?

      return value.downcase if downcase

      value
    end

    # generate_package_model generates a package model
    def generate_package_model(package, channel, subscription)
      model = {
        capabilibilities: unknown(channel.annotations.capabilities),
        categories: unknown(channel.annotations.categories),
        certified: unknown(channel.annotations.certified, 'false'),
        crds: [],
        full_description: unknown(channel.description, '', false),
        name: package.status.packageName,
        provider: 'unknown',
        repository: unknown(channel.annotations.repository),
        short_description: unknown(channel.annotations.description, '', false),
        upgradable: false,
        usage: [],
        version: unknown(subscription.status.installedCSV),
      }

      # do we have provider details
      unless package.status.provider.nil?
        model[:provider] = package.status.provider.name
      end
      if unknown(subscription.status.state) == 'upgradepending'
        model[:upgradable] = true
        model[:upgrade_version] = '0.0.3'
      end

      if !channel.icon.nil? && channel.icon.size.positive?
        if channel.icon.first.mediatype = 'image/svg+xml'
          model[:icon] = channel.icon.first.base64data
        end
      end

      # do we have any own crds?
      unless channel.customresourcedefinitions.nil?
        unless channel.customresourcedefinitions.owned.nil?
          channel.customresourcedefinitions.owned.each do |x|
            model[:crds].push(
              description: x.description,
              display_name: x.displayName,
              kind: x.kind,
              name: x.name,
              version: x.version,
            )
          end
        end
      end

      # do we have examples?
      begin
        if !channel.annotations.nil? && !channel.annotations['alm-examples'].nil?
          JSON.parse(channel.annotations['alm-examples']).each do |x|
            usage.push(
              kind: x.kind,
              api: x.apiVersion,
              example: x,
            )
          end
        end
      rescue Exception => _; end

      model
    end

    # generate_subscription_model creates a model for the subscription
    def generate_subscription_model(subscription)
      sub = {
        approvals: subscription.spec.installPlanApproval.downcase,
        name: subscription.metadata.name,
        namespace: subscription.metadata.namespace,
        installplan: 'none',
        running: 'unknown',
      }

      #parse(subscription.status.installplan)

      unless subscription.status.nil?
        status = subscription.status
        unless status.installplan.nil?
          sub[:installplan] = status.installplan.name
        end
        unless status.state.nil?
          case status.state.downcase
          when 'atlatestknown','upgradepending'
            sub[:running] = 'running'
          end
        end
      end

      sub
    end

    def parse_value(default_value = 'unknown', &block)
      begin
        value = yield block
        return value unless value.nil? && value.empty?
      rescue Exception => _; end

      default_value
    end

    # generate_catalog_model creates a model for the catalog
    def generate_catalog_model(package, subscription)
      catalog = {
        display_name: package.status.catalogSourceDisplayName,
        namespace: package.status.catalogSourceNamespace,
        publisher: package.status.catalogSourcePublisher,
        source: package.status.catalogSource,
        healthy: true,
      }

      unless subscription.nil?
        status = subscription.status
        unless status.catalogHealth.nil? && status.catalogHealth.size.negative?
          status.catalogHealth.each do |x|
            next unless x.catalogSourceRef.name == subscription.spec.source
            catalog[:healthy] = x.healthy
            catalog[:last_sync] = x.lastUpdated
          end
        end
      end

      catalog
    end

  end
end
