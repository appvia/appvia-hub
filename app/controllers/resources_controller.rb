class ResourcesController < ApplicationController
  before_action :find_project

  authorize_resource :project

  before_action :find_parent_resource, only: %i[new create]

  before_action :find_resource_type, only: %i[new create]
  before_action :find_integrations, only: %i[new create]

  before_action :find_resource, only: [:destroy]

  before_action :create_service_catalog_service, if: :service_catalog?, only: %i[new create]

  def new
    integration = @integrations.values.first.first
    @resource = @project.resources.new(
      type: @resource_type[:class],
      integration_id: integration.id
    )
    @resource.parent_id = @parent_resource&.id
  end

  def create
    @resource = @project.resources.new resource_params

    @resource.requested_by = current_user

    set_from_integration_specific_params @resource, params

    if integration_specific_prechecks(@resource, params) && @resource.save
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
    result = ProjectResourcesBootstrapService
      .new(@project)
      .bootstrap(requested_by: current_user)

    notice = ('A default set of resources have been requested for this space' if result)

    redirect_to project_path(@project, autorefresh: true), notice: notice
  end

  private

  def find_project
    @project = Project.friendly.find params[:project_id]
  end

  def find_resource_type
    @resource_type = ResourceTypesService.get params.require(:type)
  end

  def find_integrations
    is_a_dependent_resource = @parent_resource&.id.present?
    @integrations = TeamIntegrationsService
      .get(@project.team, include_dependents: is_a_dependent_resource)
      .select { |i| @resource_type[:providers].include? i.provider_id }
      .select { |i| i.parent_ids.empty? || i.parent_ids.include?(@parent_resource.integration_id) }
      .group_by { |i| i.provider['name'] }

    if @integrations.empty? # rubocop:disable Style/GuardClause
      flash[:warning] = [
        'No integrations are available for the space for the specified resource type',
        '- ask a hub admin to configure and allocate an appropriate integration to the team'
      ].join(' ')
      redirect_back fallback_location: root_path, allow_other_host: false
    end
  end

  def find_resource
    @resource = @project.resources.find params[:id]
  end

  def find_parent_resource
    parent_id = params[:parent_id] || (params.key?(:resource) && params[:resource][:parent_id])
    @parent_resource = @project.resources.find parent_id if parent_id.present?
  end

  def service_catalog?
    @resource_type[:id] == 'ServiceCatalogInstance'
  end

  def create_service_catalog_service
    integration = @resource&.integration || @integrations.values.first.first
    config = IntegrationOverridesService.new.effective_config_for integration, @project
    agent = AgentsService.get 'service_catalog', config
    @sb_service = ServiceCatalogService.new agent
  end

  def resource_params
    params.require(:resource).permit(:type, :integration_id, :name, :parent_id)
  end

  def set_from_integration_specific_params(resource, params)
    return if resource.integration.blank?

    integration_specific_params = params[:resource][@resource.integration.provider_id]
    return if integration_specific_params.blank?

    case @resource.integration.provider_id
    when 'git_hub'
      template_url = integration_specific_params['template_url_custom'].presence ||
                     integration_specific_params['template_url'].presence

      resource.template_url = template_url
    when 'service_catalog'
      integration_specific_params[:plan_parameters]&.permit!
      service_class = integration_specific_params['service_class']
      service_plan = integration_specific_params['service_plan']
      @sb_service.service_class_plan_names(service_class, service_plan)
        .each { |k, v| resource.send "#{k}=", v }
      resource.create_parameters = integration_specific_params['plan_parameters'] || {}
      unless resource.create_parameters.empty?
        resource.create_parameters_schema = @sb_service.service_plan_schema resource.class_name, resource.plan_name
      end
    end
  end

  def integration_specific_prechecks(resource, params)
    provider = (resource.integration&.provider_id)
    case provider
    when 'service_catalog'
      # this checks that the stages in the multi-step class/plan/parameters selection process are completed
      # to be complete, the class and plan must be set and the form submitted using the "Request" button
      return false unless resource.class_name && resource.plan_name && params[:commit]
    end
    true
  end
end
