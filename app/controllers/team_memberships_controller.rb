class TeamMembershipsController < ApplicationController
  before_action :find_team

  # PUT /teams/:team_id/memberships/:id
  def update
    authorize! :edit, @team

    user_id = params.require(:id)

    raise ActionController::ParameterMissing, :role unless params.key?(:role)

    role = params[:role].presence

    @team_membership = TeamMembershipsService.create_or_update!(
      team: @team,
      user_id: user_id,
      role: role
    )

    flash[:notice] = 'Team member successfully added or updated'

    respond_to do |format|
      format.json { head :no_content }
      format.js { redirect_to team_path(@team, anchor: 'people') }
      format.html { redirect_to team_path(@team, anchor: 'people') }
    end
  end

  # DELETE /teams/:team_id/memberships/:id
  def destroy
    authorize! :edit, @team

    @team_membership = TeamMembershipsService.destroy!(
      team: @team,
      user_id: params.require(:id)
    )

    redirect_to team_path(@team, anchor: 'people'), notice: 'Team member removed'
  end

  private

  def find_team
    @team = Team.friendly.find params[:team_id]
  end
end
