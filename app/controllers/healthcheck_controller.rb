class HealthcheckController < ApplicationController
  skip_before_action :require_authentication, only: :show

  def show
    head :no_content
  end
end
