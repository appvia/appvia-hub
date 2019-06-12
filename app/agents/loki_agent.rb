require 'cgi'

class LokiAgent
  def initialize(grafana_url:)
    @grafana_url = grafana_url
  end

  def construct_url(grafana_url, namespace)
    logging_view_uri="explore?left=[\"now-6h\",\"now\",\"Loki\",{\"expr\":\"{namespace=" + '\"' + "#{namespace}" + '\"' + "}\"},{\"ui\":[true,true,true,\"none\"]}]"
    logging_view_url = "#{grafana_url}/" + CGI.escape(logging_view_uri)
    puts logging_view_url
  end
end
