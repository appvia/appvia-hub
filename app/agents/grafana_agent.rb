class GrafanaAgent
  include AgentHttpClient

  def initialize(agent_base_url:, agent_token:, grafana_url:, grafana_api_key:, grafana_ca_cert:, grafana_admin_username:, grafana_admin_password:)
    @agent_base_url = agent_base_url
    @agent_token = agent_token

    @grafana_url = grafana_url
    @grafana_api_key = grafana_api_key
    @grafana_ca_cert = grafana_ca_cert

    @grafana_admin_username = grafana_admin_username
    @grafana_admin_password = grafana_admin_password
  end

  def create_dashboard(name, template_url:)
    path = dashboard_path name
    body = {
      template_url: template_url
    }
    client.put do |req|
      add_grafana_headers req
      req.url path
      req.body = body
    end.body
  end

  def update_users(users)
    path = 'users'
    users = users.map do |u|
      {
        name: u,
        login: u,
        email: u
      }
    end
    body = users.to_json
    client.put do |req|
      add_grafana_headers req
      req.url path
      req.body = body
    end.body
  end

  def delete_dashboard(name)
    path = dashboard_path name
    client.delete do |req|
      add_grafana_headers req
      req.url path
    end.body
  end

  def sync_teams(memberships)
    users = memberships.map do |membership|
      {
        name: membership.user,
        login: membership.user,
        email: membership.user
      }
    end
    body = users.to_json
    client.put do |req|
      add_grafana_headers req
      req.url path
      req.body = body
    end.body
  end

  private

  def add_grafana_headers(req)
    req.headers['X-Grafana-URL'] = @grafana_url
    req.headers['X-Grafana-API-Key'] = @grafana_api_key
    req.headers['X-Grafana-Basic-Auth'] = Base64.strict_encode64("#{@grafana_admin_username}:#{@grafana_admin_password}")
    req.headers['X-Grafana-CA'] = @grafana_ca_cert
    req.headers['X-Grafana-Basic-Auth'] = Base64.strict_encode64("#{@grafana_admin_username}:#{@grafana_admin_password}")
  end

  def dashboard_path(name)
    "dashboards/#{name}"
  end
end
