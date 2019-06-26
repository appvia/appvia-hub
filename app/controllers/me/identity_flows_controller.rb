module Me
  class IdentityFlowsController < ApplicationController
    ACTION_TO_PROVIDER_IDS = {
      'git_hub_start' => 'git_hub',
      'git_hub_callback' => 'git_hub'
    }.freeze

    skip_before_action :require_authentication, only: :git_hub_callback

    before_action :find_integration

    before_action :ensure_valid_action_for_integration

    def git_hub_start
      callback_url = URI.join(
        Rails.configuration.base_url,
        me_identity_flow_git_hub_callback_path(integration_id: @integration.id)
      ).to_s

      redirect_to git_hub_identity_service.authorize_url(
        current_user,
        callback_url
      )
    end

    # Called by GitHub as part of it's OAuth2 flow
    def git_hub_callback
      code, state = params.require(%i[code state])

      begin
        git_hub_identity_service.connect_identity @integration, code, state
      rescue GitHubIdentityService::InvalidCallbackState
        logger.error "GitHub identity flow callback was called with an invalid 'state' = #{state}"
        head(:forbidden) && return
      rescue GitHubIdentityService::NoAccessToken
        logger.error 'GitHub identity flow was unable to get an access token'
        head(:forbidden) && return
      rescue GitHubIdentityService::MismatchWithExistingUser
        logger.error [
          "GitHub identity flow returned a GitHub user already connected to a different hub user's identity (i.e. different to the user specified",
          "in the 'state' at the beginning of the auth flow)"
        ].join(' ')
        head(:forbidden) && return
      end

      redirect_to me_access_path, notice: 'GitHub identity connected'
    end

    private

    def find_integration
      @integration = Integration.find params[:integration_id]
    end

    def ensure_valid_action_for_integration
      unprocessable_entity_error if ACTION_TO_PROVIDER_IDS[action_name] != @integration.provider_id
    end

    def git_hub_identity_service
      config = @integration.config

      GitHubIdentityService.new(
        encryption_service: ENCRYPTOR,
        client_id: config['app_client_id'],
        client_secret: config['app_client_secret']
      )
    end
  end
end
