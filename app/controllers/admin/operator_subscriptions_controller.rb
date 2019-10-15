module Admin
  class OperatorSubscriptionsController < BaseController
    before_action :find_integration

    authorize_resource class: false

    # GET /admin/operator_subscriptions/:integration_id
    def index
      @subscriptions = @service.list
    end

    # GET /admin/operator_subscriptions/:integration_id/:namespace/:name
    def show
      name = params[:name]
      namespace = params[:namespace]

      model = @service.get(namespace, name)

      @catalog = model[:catalog]
      @channel = model[:channel]
      @info = model[:info]
      @package = model[:package]
      @subscription = model[:subscription]
    end

    # GET /admin/operator_subscriptions/:integration_id/:namespace/:name/approve
    def approve
      name = params[:name]
      namespace = params[:namespace]

      @service.approve(namespace, name)

      redirect_to admin_operator_subscriptions_path @integration, notice: 'Upgrade has been approved and will be upgraded in background'
    end

    private

    # rubocop:disable Metrics/LineLength
    def find_integration
      @integration = Integration.find params[:integration_id]
      unless @integration.kubernetes?
        Rails.logger.warn "Integration '#{@integration.name}' (ID: #{@integration.id}) needs to be for provider 'kubernetes' in order for this route to work"
        unprocessable_entity_error
        return
      end

      @agent = AgentsService.get('operator', @integration.config)
      @service = OperatorSubscriptionsService.new(@agent)
    end
    # rubocop:enable Metrics/LineLength
  end
end
