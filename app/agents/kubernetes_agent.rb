class KubernetesAgent
  include AgentHttpClient

  SERVICE_ACCOUNTS_NAMESPACE = 'default'.freeze

  def initialize(agent_base_url:, agent_token:, kube_api_url:, kube_ca_cert:, kube_token:)
    @agent_base_url = agent_base_url
    @agent_token = agent_token

    @kube_api_url = kube_api_url
    @kube_ca_cert = kube_ca_cert
    @kube_token = kube_token
  end

  # `service_accounts` is expected to be an array of hashes, of the form:
  # [
  #   { name: '<name>' },
  #   ...
  # ]
  def create_namespace(name, service_accounts: [])
    service_accounts = service_accounts.map do |e|
      e[:namespace] = SERVICE_ACCOUNTS_NAMESPACE
      e
    end

    path = namespace_path name
    body = {
      name: name,
      spec: {
        service_accounts: service_accounts
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

  def create_service_account(name)
    path = service_account_path name
    body = {
      spec: {
        name: name
      }
    }
    client.put do |req|
      add_kube_auth_headers req
      req.url path
      req.body = body
    end.body
  end

  def delete_service_account(name)
    path = service_account_path name
    client.delete do |req|
      add_kube_auth_headers req
      req.url path
    end.body
  end

  def get_all_deployed_versions(namespace)
    client.options.open_timeout = 0.01
    client.options.timeout = 0.01
    client.get do |req|
      add_kube_auth_headers req
      req.url "versions/#{namespace}"
    end.body
  end

  private

  def add_kube_auth_headers(req)
    req.headers['X-Kube-API-URL'] = @kube_api_url
    req.headers['X-Kube-CA'] = @kube_ca_cert
    req.headers['X-Kube-Token'] = @kube_token
  end

  def namespace_path(name)
    "namespaces/#{name}"
  end

  def service_account_path(name)
    "service-accounts/#{SERVICE_ACCOUNTS_NAMESPACE}/#{name}"
  end
end
