class ResourcesController < ApplicationController
  before_action :find_project

  before_action :find_resource_type, only: %i[new create]
  before_action :find_integrations_for_resource_type, only: %i[new create]

  before_action :find_resource, only: [:destroy]

  def new
    @resource = @project.resources.new type: @resource_type[:class]
  end

  def create
    @resource = @project.resources.new resource_params

    if @resource.save
      ResourceProvisioningService.new.request_create @resource

      notice_message = 'Resource has been requested. The page will now refresh automatically to update the status of resources.'
      redirect_to project_path(@project, autorefresh: true), notice: notice_message
    else
      render :new
    end
  end

  def destroy
    ResourceProvisioningService.new.request_delete @resource

    notice_message = 'Deletion of resource has been requested. The page will now refresh automatically to update the status of resources.'
    redirect_to project_path(@project, autorefresh: true), notice: notice_message
  end

  def prepare_bootstrap
    @prepare_results = ProjectResourcesBootstrapService.new(@project).prepare_bootstrap

    if @prepare_results.blank? # rubocop:disable Style/GuardClause
      flash[:warning] = 'Can\'t bootstrap resources for the space - the space may already have some resources'
      redirect_back fallback_location: root_path, allow_other_host: false
    end
  end

  def bootstrap
    result = ProjectResourcesBootstrapService.new(@project).bootstrap

    notice = ('A default set of resources have been requested for this space' if result)

    redirect_to @project, notice: notice
  end

  private

  def find_project
    @project = Project.friendly.find params[:project_id]
  end

  def find_resource_type
    @resource_type = ResourceTypesService.get params.require(:type)
  end

  def find_integrations_for_resource_type
    @integrations = ResourceTypesService.integrations_for @resource_type[:id]

    if @integrations.empty? # rubocop:disable Style/GuardClause
      flash[:warning] = 'No integrations are available for the resource type - ask a hub admin to configure an appropriate integration'
      redirect_back fallback_location: root_path, allow_other_host: false
    end
  end

  def find_resource
    @resource = @project.resources.find params[:id]
  end

  def resource_params
    params.require(:resource).permit(:type, :integration_id, :name)
  end
end
