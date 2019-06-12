require 'cgi'

class LokiAgent
  def initialize(grafana_url:)
    @grafana_url = grafana_url
  end

  def construct_logging_view_url(namespace)
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
end
