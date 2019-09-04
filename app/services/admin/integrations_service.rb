module Admin
  module IntegrationsService
    class << self
      def create(params)
        integration = Integration.new params

        success = integration.save

        handle_integration_update(integration) if success

        [integration, success]
      end

      def update(integration, params)
        success = integration.update params

        handle_integration_update(integration) if success

        success
      end

      private

      def handle_integration_update(integration)
        teams = TeamIntegrationsService.bifurcate_teams(
          Team.all.entries,
          integration
        )

        Teams::HandleIntegrationTeamsUpdateWorker.perform_async(
          integration.id,
          teams[:allowed].map(&:id),
          teams[:not_allowed].map(&:slug)
        )
      end
    end
  end
end
