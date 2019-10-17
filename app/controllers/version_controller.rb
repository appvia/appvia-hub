class VersionController < ApplicationController
  skip_before_action :require_authentication, only: :show

  skip_authorization_check

  def show
    render json: { version: Rails.configuration.version }
  end
end
