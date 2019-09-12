class GitHubIdentityService
  class InvalidCallbackState < StandardError
  end

  class NoAccessToken < StandardError
  end

  class MismatchWithExistingUser < StandardError
  end

  def initialize(encryption_service:, client_id:, client_secret:)
    @encryption_service = encryption_service
    @client_id = client_id
    @client_secret = client_secret
  end

  def authorize_url(user, callback_url)
    Octokit::Client.new.authorize_url(
      @client_id,
        scope: '',
        redirect_uri: callback_url,
        state: Base64.urlsafe_encode64(@encryption_service.encrypt(user.id))
    )
  end

  def connect_identity(integration, code, state)
    user_id = @encryption_service.decrypt(Base64.urlsafe_decode64(state))
    user = User.find_by id: user_id

    raise InvalidCallbackState if user.blank?

    result = Octokit.exchange_code_for_token(code, @client_id, @client_secret)
    access_token = result[:access_token]

    raise NoAccessToken if access_token.blank?

    git_hub_client = Octokit::Client.new
    git_hub_client.access_token = access_token
    git_hub_user = git_hub_client.user

    identity = process(
      integration,
      user,
      git_hub_user,
      access_token
    )

    identity
  end

  private

  def process(integration, user, git_hub_user, access_token)
    identity = integration.user_identities.find_by(external_id: git_hub_user.id)

    if identity.blank?
      identity = IdentitiesService.create!(
        integration.user_identities,
        user: user,
        external_id: git_hub_user.id,
        external_username: git_hub_user.login,
        external_name: git_hub_user.name,
        external_email: git_hub_user.email,
        access_token: access_token
      )
    elsif identity.user_id != user.id
      raise MismatchWithExistingUser
    else
      # Update the existing identity with latest from the GitHub user profile
      IdentitiesService.update!(
        identity,
        external_username: git_hub_user.login,
        external_name: git_hub_user.name,
        external_email: git_hub_user.email,
        access_token: access_token
      )
    end

    identity
  end
end
