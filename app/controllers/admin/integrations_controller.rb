module Admin
  class IntegrationsController < Admin::BaseController
    before_action :find_integration, only: %i[edit update]

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

      @integration = Integration.new provider_id: provider_id
    end

    # GET /admin/integrations/:id/edit
    def edit
      @potential_parents = find_potential_parents @integration.provider_id
    end

    # POST /admin/integrations
    def create
      params = integration_params

      params[:parent_ids].reject!(&:blank?) if params.key?(:parent_ids)

      @integration = Integration.new params

      if @integration.save
        path = helpers.admin_integrations_path_with_selected @integration
        redirect_to path, notice: 'New integration was successfully created.'
      else
        @potential_parents = find_potential_parents @integration.provider_id
        render :new
      end
    end

    # PATCH/PUT /admin/integrations/:id
    def update
      params = integration_params

      params[:parent_ids].reject!(&:blank?) if params.key?(:parent_ids)

      if @integration.update params
        path = helpers.admin_integrations_path_with_selected @integration
        redirect_to path, notice: 'Integration was successfully updated.'
      else
        @potential_parents = find_potential_parents @integration.provider_id
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

    def integration_params
      params.require(:integration).permit(:provider_id, :name, parent_ids: [], config: {})
    end
  end
end
