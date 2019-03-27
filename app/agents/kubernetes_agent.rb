class KubernetesAgent
  include AgentHttpClient

  def initialize(agent_base_url:, agent_token:, kube_api_url:, kube_ca_cert:, kube_token:, global_service_account_name:)
    @agent_base_url = agent_base_url
    @agent_token = agent_token

    @kube_api_url = kube_api_url
    @kube_ca_cert = kube_ca_cert
    @kube_token = kube_token

    @global_service_account_name = global_service_account_name
  end

  def create_namespace(name)
    path = namespace_path name
    body = {
      name: name,
      spec: {
        service_accounts: [
          {
            name: @global_service_account_name
          }
        ]
      }
    }
    client.put do |req|
      add_kube_auth_headers req
      req.url path
      req.body = body
    end.body
  end

  def delete_namespace(name)
    path = namespace_path name
    client.delete do |req|
      add_kube_auth_headers req
      req.url path
    end.body
  end

  private

  def add_kube_auth_headers(req)
    req.headers['X-Kube-API-URL'] = @kube_api_url
    req.headers['X-Kube-CA'] = @kube_ca_cert
    req.headers['X-Kube-Token'] = @kube_token
  end

  def namespace_path(name)
    "/namespaces/#{name}"
  end
end
