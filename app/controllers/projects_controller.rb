class ProjectsController < ApplicationController
  before_action :load_and_check_presence_of_teams, only: %i[new edit create update]

  before_action :find_project, only: %i[show edit update destroy]

  def index
    @projects = Project.order(:name)
  end

  def show
    @grouped_resources = ResourceTypesService.all.map do |rt|
      next nil unless rt[:top_level]

      integrations = ResourceTypesService.integrations_for rt[:id]
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
    @project.destroy
    redirect_to projects_url, notice: 'Space was successfully deleted.'
  end

  private

  def load_and_check_presence_of_teams
    @teams = Team.all

    if @teams.empty? # rubocop:disable Style/GuardClause
      flash[:warning] = 'No teams have been created yet, so spaces cannot be created.'
      redirect_back fallback_location: root_path, allow_other_host: false
    end
  end

  def find_project
    @project = Project.friendly.find params[:id]
  end

  def project_params
    params.require(:project).permit(:name, :slug, :description, :team_id)
  end
end
