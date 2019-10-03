module Admin
  class IntegrationsController < BaseController
    before_action :find_integration, only: %i[edit update]

    authorize_resource

    # GET /admin/integrations
    def index
      integrations_by_provider = Integration.all.group_by(&:provider_id)

      @group_to_expand = params[:expand]
      @unmask = params.key? 'unmask'

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
  end
end
