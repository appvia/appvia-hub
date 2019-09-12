class UsersController < ApplicationController
  authorize_resource

  # GET /users
  def index
    @users = User.order(:email)
  end

  # GET /users/search
  def search
    query = params.require(:q)
    users = User.search query

    respond_to do |format|
      format.any { render json: users, content_type: 'application/json' }
    end
  end

  # PUT/PATCH /users/:user_id/role
  def update_role
    user = User.find params[:user_id]

    user.role = params.require('role')
    user.save!

    redirect_to users_path, notice: "User's role has been updated"
  end
end
