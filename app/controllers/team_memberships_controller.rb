class TeamMembershipsController < ApplicationController
  before_action :find_team

  def update
    @team_membership = team_membership_scope.first_or_initialize

    @team_membership.role = params[:role] if params.key?(:role)

    @team_membership.save!

    flash[:notice] = 'Team member successfully added or updated'

    respond_to do |format|
      format.json { head :no_content }
      format.js { redirect_to team_path(@team, anchor: 'people') }
      format.html { redirect_to team_path(@team, anchor: 'people') }
    end
  end

  def destroy
    @team_membership = team_membership_scope.first

    @team_membership&.destroy

    redirect_to team_path(@team, anchor: 'people'), notice: 'Team member removed'
  end

  private

  def find_team
    @team = Team.friendly.find params[:team_id]
  end

  def team_membership_scope
    user_id = params.require :id
    @team
      .memberships
      .where(user_id: user_id)
  end
end
