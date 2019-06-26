class HandleIdentityDeletedWorker
  include Sidekiq::Worker

  def perform(integration_id, external_info)
    integration = Integration.find_by id: integration_id

    return if integration.nil?

    config = integration.config

    case integration.provider_id
    when 'git_hub'
      agent = AgentsService.get integration.provider_id, config
      agent.remove_user_from_team config['all_team_id'], external_info['Username']
    end
  end
end
