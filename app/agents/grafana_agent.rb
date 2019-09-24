class GrafanaAgent
  include AgentHttpClient

  def initialize(agent_base_url:, agent_token:, url:, api_key:, ca_cert:, admin_username:, admin_password:)
    @agent_base_url = agent_base_url
    @agent_token = agent_token

    @url = url
    @api_key = api_key
    @ca_cert = ca_cert

    @admin_username = admin_username
    @admin_password = admin_password
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

  def delete_dashboard(name)
    path = dashboard_path name
    client.delete do |req|
      add_grafana_headers req
      req.url path
    end.body
  end

  def sync_team(memberships)
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
    req.headers['X-Grafana-URL'] = @url
    req.headers['X-Grafana-API-Key'] = @api_key
    req.headers['X-Grafana-CA'] = @ca_cert
    req.headers['X-Grafana-Basic-Auth'] = Base64.strict_encode64("#{@admin_username}:#{@admin_password}")
  end

  def dashboard_path(name)
    "dashboards/#{name}"
  end
end
