class HomeController < ApplicationController
  skip_authorization_check

  def show
    @activity = ActivityService.new.overall current_user
  end
end
