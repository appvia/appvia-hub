class LokiAgent
  def initialize(grafana_url:)
    @grafana_url = grafana_url
  end

  def create_logging_dashboard(name, query_expression, grafana_url:)
    logging_view_uri = 'explore?left=[' \
                          '"now-6h",' \
                          '"now",' \
                          '"Loki",' \
                          '{' \
                            '"expr":"' + query_expression + '"' \
                          '},' \
                          '{' \
                            '"ui":[true,true,true,"none"]' \
                          '}' \
                        ']'
    if grafana_url.end_with?('/')
      @grafana_url + CGI.escape(logging_view_uri)
    else
      @grafana_url + '/' + CGI.escape(logging_view_uri)
    end
  end
end
