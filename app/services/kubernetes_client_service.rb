class KubernetesClientService
  attr_accessor :endpoint, :client

  def initialize(url, token: nil, client_certificate: nil, client_key: nil, certificate_authority: nil)
    @endpoint = url

    config = K8s::Config.new(
      clusters: [{
        name: 'default',
        cluster: {
          server: @endpoint,
          certificate_authority_data: certificate_authority
        }
      }],
      users: [{
        name: 'default',
        user: {
          token: token,
          client_certificate_data: client_certificate,
          client_key_data: client_key
        }
      }],
      contexts: [{
        name: 'default',
        context: { cluster: 'default', user: 'default' }
      }],
      current_context: 'default'
    )
    @client = K8s::Client.config(config, ssl_verify_peer: certificate_authority.present?)
  end

  # kubectl is used to apply a manifest
  def kubectl(manifest)
    resource = K8s::Resource.from_json(YAML.safe_load(manifest).to_json)

    raise ArgumentError, 'no api version associated to resource' unless extract(nil) { resource.apiVersion }
    raise ArgumentError, 'no kind associated to resource' unless extract(nil) { resource.kind }
    raise ArgumentError, 'no metadata associated to resource' unless extract(nil) { resource.metadata.name }

    name = resource.metadata.name
    namespace = resource.metadata.namespace
    kind = with_kind(kind)
    version = resource.apiVersion

    return @client.api(version).resource(kind, namespace: namespace).update_resource(resource) if exists?(namespace, name, kind, version)

    @client.api(version).resource(kind, namespace: namespace).create_resource(resource)
  end

  # exist? checks if a resource exists
  def exist?(namespace, name, kind, version = 'v1')
    begin
      @client.api(version)
        .resource(with_kind(kind), namespace: namespace)
        .get(name)
    rescue K8s::Error::NotFound
      return false
    end
    true
  end

  private

  # extract is a helper method to aid in extracting values from the resource
  # rubocop:disable Lint/HandleExceptions
  def extract(default_value = 'unknown', &block)
    begin
      value = yield block
      unless value.nil?
        return value unless value.class == String.class
        return value unless value.empty?
      end
    rescue NoMethodError, TypeError => _e; end
    default_value
  end
  # rubocop:enable Lint/HandleExceptions

  # with_kind converts the resource kind into a plural
  def with_kind(kind)
    case kind
    when 'ingresses'
      return kind
    end
    return "#{kind}s" unless kind.end_with?('s')

    kind
  end
end
