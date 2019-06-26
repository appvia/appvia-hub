module AgentsService
  class << self
    AGENT_INITIALISERS = {
      'git_hub' => lambda do |config|
        GitHubAgent.new(
          app_id: config['app_id'],
          app_private_key: config['app_private_key'],
          app_installation_id: config['app_installation_id'],
          org: config['org']
        )
      end,
      'ecr' => lambda do |config|
        ECRAgent.new(
          agent_base_url: Rails.configuration.agents.ecr.base_url,
          agent_token: Rails.configuration.agents.ecr.token,
          org: config['org'],
          access_id: config['access_id'],
          access_token: config['access_token'],
          region: config['region'],
          account: config['account'],
          global_robot_name: config['global_robot_name']
        )
      end,
      'quay' => lambda do |config|
        QuayAgent.new(
          agent_base_url: Rails.configuration.agents.quay.base_url,
          agent_token: Rails.configuration.agents.quay.token,
          quay_access_token: config['api_access_token'],
          org: config['org'],
          global_robot_name: config['global_robot_name']
        )
      end,
      'kubernetes' => lambda do |config|
        KubernetesAgent.new(
          agent_base_url: Rails.configuration.agents.kubernetes.base_url,
          agent_token: Rails.configuration.agents.kubernetes.token,
          kube_api_url: config['api_url'],
          kube_ca_cert: config['ca_cert'],
          kube_token: config['token'],
          global_service_account_name: config['global_service_account_name']
        )
      end,
      'grafana' => lambda do |config|
        GrafanaAgent.new(
          agent_base_url: Rails.configuration.agents.grafana.base_url,
          agent_token: Rails.configuration.agents.grafana.token,
          grafana_url: config['url'],
          grafana_api_key: config['api_key'],
          grafana_ca_cert: config['ca_cert']
        )
      end,
      'loki' => lambda do |config|
        LokiAgent.new(
          grafana_url: config['grafana_url']
        )
      end
    }.freeze

    def get(provider_id, config)
      agent_initialiser = AGENT_INITIALISERS[provider_id]
      agent_initialiser&.call config
    end
  end
end
