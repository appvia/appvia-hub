class ProjectsController < ApplicationController
  before_action :load_and_check_presence_of_teams, only: %i[new edit create update]

  before_action :check_team_param_is_allowed, only: %i[new edit create update]

  before_action :find_project, only: %i[show edit update destroy]

  skip_authorization_check only: %i[index]

  authorize_resource except: %i[index]

  def index
    @projects = Project.order(:name)
  end

  def show
    integrations_by_provider = TeamIntegrationsService
      .get(@project.team)
      .group_by(&:provider_id)

    @grouped_resources = ResourceTypesService.all.map do |rt|
      next nil unless rt[:top_level]

      integrations = rt[:providers].reduce([]) do |acc, p|
        acc + Array(integrations_by_provider[p])
      end

      resources = @project.send(rt[:id].tableize).order(:name)

      rt.merge integrations: integrations, resources: resources
    end.compact

    @activity = ActivityService.new.for_project @project
  end

  def new
    @project = Project.new team_id: params[:team_id]
  end

  def edit; end

  def create
    @project = Project.new project_params

    if @project.save
      redirect_to @project, notice: 'Space was successfully created.'
    else
      render :new
    end
  end

  def update
    if @project.update project_params
      redirect_to @project, notice: 'Space was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    team_id = @project.team_id

    @project.destroy

    redirect_to team_path(team_id), notice: 'Space was successfully deleted.'
  end

  private

  def load_and_check_presence_of_teams
    @teams = current_user.admin? ? Team.all : current_user.teams

    if @teams.empty? # rubocop:disable Style/GuardClause
      flash[:warning] = 'No teams available.'
      redirect_back fallback_location: root_path, allow_other_host: false
    end
  end

  def check_team_param_is_allowed
    return if current_user.admin?

    team_id = params[:team_id] || (params.key?(:project) && params[:project][:team_id])

    return if team_id.blank?

    is_allowed_team = @teams.any? { |t| t.id == team_id }

    access_denied('not allowed access to the team specified') unless is_allowed_team
  end

  def find_project
    @project = Project.friendly.find params[:id]
  end

  def project_params
    params.require(:project).permit(:name, :slug, :description, :team_id)
  end
end
