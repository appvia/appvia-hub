module Me
  class IdentitiesController < ApplicationController
    before_action :find_integration

    def destroy
      identity = current_user.identities.find_by(integration_id: @integration.id)

      raise ActiveRecord::RecordNotFound if identity.blank?

      identity.destroy!

      redirect_to me_access_path, notice: 'Identity disconnected'
    end

    private

    def find_integration
      @integration = Integration.find params[:integration_id]
    end
  end
end
