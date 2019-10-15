# rubocop:disable Metrics/ClassLength
class OperatorAgent
  # is the main api version
  API_V1 = 'operators.coreos.com/v1'.freeze
  API_ALPHA_V1 = 'operators.coreos.com/v1alpha1'.freeze
  PACKAGE_API_V1 = 'packages.operators.coreos.com/v1'.freeze

  def initialize(url:, token: nil, ca_cert: nil, client_certificate: nil, client_key: nil)
    verify_tls = ca_cert.present?

    # create a kubernetes client
    config = K8s::Config.new(
      clusters: [{
        name: 'default',
        cluster: {
          server: url,
          certificate_authority_data: ca_cert
        }
      }],
      users: [{
        name: 'default',
        user: {
          client_certificate_data: client_certificate,
          client_key_data: client_key,
          token: token
        }
      }],
      contexts: [{
        name: 'default',
        context: { cluster: 'default', user: 'default' }
      }],
      current_context: 'default'
    )
    @client = K8s::Client.config(config, ssl_verify_peer: verify_tls)
  end

  # approve_subscription is responsible for approving the installation of an operator
  def approve_subscription(namespace, name)
    # return the resource
    subscription = get_subscription(namespace, name)
    raise StandardError, "subscription, name: #{name}, namespace: #{namespace} does not exist" if subscription.nil?

    status = subscription.status
    raise StandardError, "subscription, name: #{name}, namespace: #{namespace} has no status" if status.nil?
    raise StandardError, "subscription, name: #{name}, namespace: #{namespace} has no state" if status.state.nil?

    state = status.state
    return unless state.casecmp('upgradepending').zero?

    installplan_name = status.installplan.name
    installplan = get_installplan(namespace, installplan_name)
    raise StandardError, "installplan, name: #{installplan_name}, namespace: #{namespace} does not exist" if installplan.nil?

    installplan.spec.approved = true

    # fire off the resource update
    @client.api(API_ALPHA_V1)
      .resource('installplans', namespace: namespace)
      .update_resource(installplan)
  end

  # create_subscription is responsible for creating a subscription to a operator
  def create_subscription(name:, namespace:, package:, channel:,
                          plan: 'Manual', version: nil, catalog: 'operatorhubio-catalog')
    # check if the subscription exists already
    return if subscription?(package, namespace)

    @client.api(API_ALPHA_V1).resource('subscriptions')
      .create(K8s::Resource.new(
                apiVersion: API_ALPHA_V1,
                kind: 'Subscription',
                metadata: {
                  name: name,
                  namespace: namespace
                },
                spec: {
                  name: name,
                  channel: channel,
                  installPlanApproval: plan,
                  source: catalog,
                  sourceNamespace: 'olm',
                  startingCSV: version
                }
              ))
  end

  # delete_subscription is responsible for deleting a subscription to an operator
  def delete_subscription(namespace, name)
    return unless subscription?(name, namespace)

    handle_not_found do
      @client.api(API_ALPHA_V1).resource('subscriptions').delete(name)
    end
  end

  # get_subscription is responsible for returning a subscription
  def get_subscription(namespace, name)
    handle_not_found do
      @client.api(API_ALPHA_V1)
        .resource('subscriptions', namespace: namespace)
        .get(name)
    end
  end

  # get_package returns the packagemanifest
  def get_package(name, _catalog)
    handle_not_found do
      @client.api(PACKAGE_API_V1)
        .resource('packagemanifests', namespace: 'olm')
        .get(name)
    end
  end

  # get_catalog returns the catalog
  def get_catalog(name)
    handle_not_found do
      @client.api(API_ALPHA_V1)
        .resource('catalogs', namespace: 'olm')
        .get(name)
    end
  end

  # get_package_by_channel returns the package from a channel
  def get_package_by_channel(name, catalog, channel)
    package = get_package(name, catalog)
    return nil if package.nil?
    raise ArgumentError, "package: #{name} in catalog: #{catalog} has no status yet" if package.status.nil?
    raise ArgumentError, "package: #{name} in catalog: #{catalog} has no channels" if package.status.channels.nil?

    package.status.channels.each do |x|
      next unless x.name == channel

      return x.currentCSVDesc
    end

    nil
  end

  # get_installplan is responsible for returning the latest installplan for a subscription
  def get_installplan(namespace, name)
    handle_not_found do
      @client.api(API_ALPHA_V1)
        .resource('installplans', namespace: namespace)
        .get(name)
    end
  end

  # list_subscriptions provides a list of subscriptions in the cluster
  def list_subscriptions(namespace: nil)
    handle_not_found do
      @client.api(API_ALPHA_V1)
        .resource('subscriptions', namespace: namespace)
        .list
    end
  end

  # list_packages is responsible for listing packages in a or all catalogs
  def list_packages(catalog: nil)
    @client.api(PACKAGE_API_V1).resource('packagemanifests').list.select do |x|
      if catalog.nil?
        true
      else
        x.status.catalogSource.equal?(catalog)
      end
    end
  end

  # list_install_plans returns a list of the installplans
  def list_install_plans(namespace: nil)
    @client.api(API_ALPHA_V1)
      .resource('installplans', namespace: namespace)
      .list
  end

  # list_clusterserviceversions returns a list of clusterserviceversions
  def list_clusterserviceversions
    @client.api(API_ALPHA_V1)
      .resource('clusterserviceversions')
      .list
  end

  # catalog? checks the catalog exists
  def catalog?(name)
    !get_catalog(name).nil?
  end

  def handle_not_found(&block)
    yield block
  rescue K8s::Error::NotFound
    nil
  end

  # subscription? checks if a subscription exists
  def subscription?(namespace, name)
    begin
      @client.api(API_ALPHA_V1)
        .resource('subscriptions', namespace: namespace)
        .get(name)
    rescue K8s::Error::NotFound
      return false
    end
    true
  end

  # install_plan? checks is a installplan exists
  def install_plan?(namespace, name)
    begin
      @client.api(API_V1)
        .resource('installplans', namespace: namespace)
        .get(name)
    rescue K8s::Error::NotFound
      return false
    end
    true
  end

  # parse_version is responsible for parsing a csv version
  def parse_version(version)
    return 'unknown' if version.blank?

    version.split('.').drop(1).join('.')
  end
end
# rubocop:enable Metrics/ClassLength
