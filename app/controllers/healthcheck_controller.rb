class HealthcheckController < ApplicationController
  skip_before_action :require_authentication, only: :show

  skip_authorization_check

  def show
    head :no_content
  end
end
