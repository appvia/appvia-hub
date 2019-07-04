class ProjectsController < ApplicationController
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
    @project = Project.new
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

  def find_project
    @project = Project.friendly.find params[:id]
  end

  def project_params
    params.require(:project).permit(:name, :slug, :description)
  end
end
