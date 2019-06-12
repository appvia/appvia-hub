require 'cgi'

class LokiAgent
  def initialize(grafana_url:)
    @grafana_url = grafana_url
  end

  def create_logging_view(namespace)
    logging_view_uri = 'explore?left=[
                          "now-6h",
                          "now",
                          "Loki",
                          {
                            "expr":"{namespace=\"' + namespace + '\"}
                          },
                          {
                            "ui":[true,true,true,"none"]
                          }
                        ]'
    if grafana_url.end_with?('/')
      @grafana_url + '/' + CGI.escape(logging_view_uri)
    else
      @grafana_url + CGI.escape(logging_view_uri)
    end
  end

  def delete_logging_view(_namespace)
    true
  end
end
