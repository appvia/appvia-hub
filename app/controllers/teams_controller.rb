class TeamsController < ApplicationController
  before_action :find_team, only: %i[show edit update destroy]

  skip_authorization_check only: %i[index new create]

  authorize_resource except: %i[index new create]

  # GET /teams
  def index
    @teams = Team.order(:name)
  end

  # GET /teams/1
  def show
    @activity = ActivityService.new.for_team @team
  end

  # GET /teams/new
  def new
    @team = Team.new
  end

  # GET /teams/1/edit
  def edit; end

  # POST /teams
  def create
    @team = Team.new team_params

    if @team.save
      # Current user becomes an admin of the team
      @team.memberships.create! user_id: current_user.id, role: 'admin'

      redirect_to @team, notice: 'Team was successfully created.'
    else
      render :new
    end
  end

  # PATCH/PUT /teams/1
  def update
    if @team.update team_params
      redirect_to @team, notice: 'Team was successfully updated.'
    else
      render :edit
    end
  end

  # DELETE /teams/1
  def destroy
    @team.destroy
    redirect_to teams_url, notice: 'Team was successfully destroyed.'
  end

  private

  def find_team
    @team = Team.friendly.find params[:id]
  end

  def team_params
    params.require(:team).permit(:name, :slug, :description)
  end
end
