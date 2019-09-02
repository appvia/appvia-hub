class ResourcesController < ApplicationController
  before_action :find_project

  authorize_resource :project

  before_action :find_resource_type, only: %i[new create]
  before_action :find_integrations, only: %i[new create]

  before_action :find_resource, only: [:destroy]

  before_action :find_parent_resource, only: [:new]

  def new
    integration = @integrations.values.first.first
    @resource = @project.resources.new(
      type: @resource_type[:class],
      integration_id: integration.id
    )
    @resource.parent_id = @parent_resource&.id

    if @resource_type[:id] == 'ServiceBrokerInstance' # rubocop:disable Style/GuardClause
      agent = get_provider_agent integration, @project
      @service_classes = agent.get_options
    end
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
    parent_id = params[:parent_id] || (params.key?(:resource) && params[:resource][:parent_id])
    is_a_dependent_resource = parent_id.present?
    @integrations = TeamIntegrationsService
      .get(@project.team, include_dependents: is_a_dependent_resource)
      .select { |i| @resource_type[:providers].include? i.provider_id }
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
    @parent_resource = @project.resources.find params['parent_id'] if params['parent_id']
  end

  def resource_params
    params.require(:resource).permit(:type, :integration_id, :name, :parent_id)
  end

  # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  def set_from_integration_specific_params(resource, params)
    return if resource.integration.blank?

    integration_specific_params = params['resource'][@resource.integration.provider_id]

    return if integration_specific_params.blank?

    case @resource.integration.provider_id
    when 'git_hub'
      template_url = integration_specific_params['template_url_custom'].presence ||
                     integration_specific_params['template_url'].presence

      resource.template_url = template_url
    when 'service_broker'
      if integration_specific_params['service_class'].present?
        service_class = integration_specific_params['service_class'].split('|')
        resource.class_name = service_class.first
        resource.class_external_name = service_class.second
        resource.class_display_name = service_class.third
      end
      if integration_specific_params['service_plan'].present?
        service_plan = integration_specific_params['service_plan'].split('|')
        resource.plan_name = service_plan.first
        resource.plan_external_name = service_plan.second
        resource.plan_display_name = service_plan.third
      end
      resource.create_parameters = integration_specific_params['plan_parameters'] || {}
    end
  end
  # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

  def integration_specific_prechecks(resource, params)
    provider = (resource.integration&.provider_id)
    case provider
    when 'service_broker'
      # this checks that the stages in the multi-step class/plan/parameters selection process are completed
      # to be complete, the class must be selected first, then the plan and then the form submitted using the "Request" button
      agent = get_provider_agent resource.integration, @project
      @service_classes = agent.get_options
      return false unless resource.class_name

      selected_class = @service_classes.find { |o| o.metadata.name == resource.class_name }
      @service_plans = selected_class.plans
      return false unless resource.plan_name

      selected_plan = @service_plans.find { |p| p.metadata.name == resource.plan_name }
      @service_plan_schema = selected_plan.spec.instanceCreateParameterSchema unless selected_plan.nil?
      return false unless params[:commit]
    end
    true
  end

  def get_provider_agent(integration, project)
    config = IntegrationOverridesService.new.effective_config_for integration, project
    AgentsService.get integration.provider_id, config
  end
end
