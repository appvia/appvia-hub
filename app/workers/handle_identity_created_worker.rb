class HandleIdentityCreatedWorker
  include Sidekiq::Worker

  def perform(identity_id)
    identity = Identity.find_by id: identity_id

    return if identity.nil?

    integration = identity.integration
    config = integration.config

    case integration.provider_id
    when 'git_hub'
      agent = AgentsService.get integration.provider_id, config
      agent.add_user_to_team config['all_team_id'], identity.external_username
    end
  end
end
