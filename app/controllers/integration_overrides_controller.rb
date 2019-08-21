class IntegrationOverridesController < ApplicationController
  before_action :find_project

  authorize_resource :project

  def show
    @overrideables = integration_overrides_service.overrideable_integrations(@project)

    @overrides_by_integration_id = @project
      .integration_overrides
      .each_with_object({}) do |io, acc|
        acc[io.integration.id] = io
      end
  end

  def update
    overrides = params.require(:integration_overrides).permit!.to_hash

    integration_overrides_service.update! @project, overrides

    redirect_to project_path(@project), notice: 'Integration overrides updated'
  end

  private

  def find_project
    @project = Project.friendly.find params[:project_id]
  end

  def integration_overrides_service
    IntegrationOverridesService.new
  end
end
