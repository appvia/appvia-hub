class GrafanaAgent
  include AgentHttpClient

  def initialize(agent_base_url:, agent_token:, grafana_url:, grafana_api_key:, grafana_ca_cert:)
    @agent_base_url = agent_base_url
    @agent_token = agent_token

    @grafana_url = grafana_url
    @grafana_api_key = grafana_api_key
    @grafana_ca_cert = grafana_ca_cert
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

  private

  def add_grafana_headers(req)
    req.headers['X-Grafana-URL'] = @grafana_url
    req.headers['X-Grafana-API-Key'] = @grafana_api_key
    req.headers['X-Grafana-CA'] = @grafana_ca_cert
  end

  def dashboard_path(name)
    "dashboards/#{name}"
  end
end
