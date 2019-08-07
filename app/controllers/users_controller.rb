class UsersController < ApplicationController
  before_action :require_admin, only: [:update_role]

  # GET /users
  def index
    @users = User.order(:email)
  end

  # GET /users/search
  def search
    query = params.require(:q)
    users = User.search query
    render json: users
  end

  # PUT/PATCH /users/:user_id/role
  def update_role
    user = User.find params[:user_id]

    user.role = params.require('role')
    user.save!

    redirect_to users_path, notice: "User's role has been updated"
  end
end
