class ApplicationController < ActionController::Base
  include ErrorHandlers
  include Authentication
  include Authorization

  before_action :require_authentication
  before_action :record_last_seen!

  helper_method :current_user
  helper_method :current_user?

  before_action :set_autorefresh

  protected

  def set_autorefresh
    @autorefresh = params[:autorefresh] == 'true'
    @autorefresh_interval_secs = 10.seconds
  end
end
