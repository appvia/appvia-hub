class GitHubIdentityService
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

    github_client = Octokit::Client.new
    github_client.access_token = access_token
    github_user = github_client.user

    identity = integration.user_identities.find_by(external_id: github_user.id)
    if identity.blank?
      identity = integration.user_identities.create!(
        user: user,
        external_id: github_user.id,
        external_username: github_user.login,
        external_name: github_user.name,
        external_email: github_user.email,
        access_token: access_token
      )
    elsif identity.user_id != user.id
      raise MismatchWithExistingUser
    else
      # Update the existing identity with latest from the GitHub user profile
      identity.update!(
        external_username: github_user.login,
        external_name: github_user.name,
        external_email: github_user.email,
        access_token: access_token
      )
    end

    identity
  end

  class InvalidCallbackState < StandardError
  end

  class NoAccessToken < StandardError
  end

  class MismatchWithExistingUser < StandardError
  end
end
