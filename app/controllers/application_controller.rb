class ApplicationController < ActionController::Base
  include ErrorHandlers
  include Authentication

  before_action :require_authentication
  before_action :record_last_seen!

  helper_method :current_user
  helper_method :current_user?

  before_action :set_autorefresh

  protected

  def require_admin
    redirect_to root_path, alert: 'You need to be an admin to do that' unless current_user.admin?
  end

  def set_autorefresh
    @autorefresh = params[:autorefresh] == 'true'
    @autorefresh_interval_secs = 10.seconds
  end
end
