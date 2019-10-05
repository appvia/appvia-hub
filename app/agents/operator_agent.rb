class OperatorAgent
  # is the main api version
  API_V1 = 'operators.coreos.com/v1'
  # the alpha operator api
  API_ALPHA_V1 = 'operators.coreos.com/v1alpha1'
  # the package api
  PACKAGE_API_V1 = 'packages.operators.coreos.com/v1'

  def initialize(url:, token: nil, ca: nil, client_certificate: nil, client_key: nil)
    verify_tls = false
    verify_tls = true unless ca.nil?

    # create a kubernetes client
    config = K8s::Config.new(
      clusters: [{
        name: 'default',
        cluster: {
          server: url,
          certificate_authority_data: ca
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
    @client = K8s::Client.config(config, {
      ssl_verify_peer: verify_tls
    })
  end

  # approve_subscription is responsible for approving the installation of an operator
  def approve_subscription(namespace, name)
    # return the resource
    subscription = get_subscription(namespace, name)
    if subscription.nil?
      raise ArgumentError, "subscription, name: #{name}, namespace: #{namespace} does not exist"
    end
    status = subscription.status
    if status.nil?
      raise ArgumentError, "subscription, name: #{name}, namespace: #{namespace} has no status"
    end
    if status.state.nil?
      raise ArgumentError, "subscription, name: #{name}, namespace: #{namespace} has no state"
    end

    state = status.state
    return unless state.downcase == 'upgradepending'

    installplan_name = status.installplan.name
    installplan = get_installplan(namespace, installplan_name)
    if installplan.nil?
      raise ArgumentError, "installplan, name: #{installplan_name}, namespace: #{namespace} does not exist"
    end

    installplan.spec.approved = true

    puts "updating installplan: #{installplan}"

    # fire off the resource update
    @client.api(API_ALPHA_V1).
      resource('installplans', namespace: namespace).
      update_resource(installplan)
  end

  # create_subscription is responsible for creating a subscription to a operator
  def create_subscription(name:, namespace:, package:, channel:,
                          plan: 'Manual', version: nil, catalog: 'operatorhubio-catalog')
    # check if the subscription exists already
    return if subscription?(package, namespace)

    @client.api(API_ALPHA_V1).resource('subscriptions').
      create(K8s::Resource.new(
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
        },
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
      @client.api(API_ALPHA_V1).
        resource('subscriptions', namespace: namespace).
        get(name)
    end
  end

  # get_package returns the packagemanifest
  def get_package(name, catalog)
    handle_not_found do
      @client.api(PACKAGE_API_V1).
        resource('packagemanifests', namespace: 'olm').
        get(name)
    end
  end

  # get_catalog returns the catalog
  def get_catalog(name)
    handle_not_found do
      @client.api(API_ALPHA_V1).
        resource('catalogs', namespace: 'olm').
        get(name)
    end
  end

  # get_package_by_channel returns the package from a channel
  def get_package_by_channel(name, catalog, channel)
    package = get_package(name, catalog)
    if package.nil?
      return nil
    end
    if package.status.nil?
      raise ArgumentError, "package: #{name} in catalog: #{catalog} has no status yet"
    end
    if package.status.channels.nil?
      raise ArgumentError, "package: #{name} in catalog: #{catalog} has no channels"
    end

    package.status.channels.each do |x|
      next unless x.name == channel

      return x.currentCSVDesc
    end

    nil
  end

  # get_installplan is responsible for returning the latest installplan for a subscription
  def get_installplan(namespace, name)
    handle_not_found do
      @client.api(API_ALPHA_V1).
        resource('installplans', namespace: namespace).
        get(name)
    end
  end

  # list_subscriptions provides a list of subscriptions in the cluster
  def list_subscriptions(namespace: nil)
    @client.api(API_ALPHA_V1).
      resource('subscriptions', namespace: namespace).
      list
  end

  # list_subscriptions_updates is responsible for providing a list of subscriptions
  # broken down by package and namespace - essentially this is a helper method for
  # the UI to display
  def list_subscriptions_updates
    operators = []
    packages = {}

    begin
      list_subscriptions.each do |x|
        # ignore anything that doesn't have a status yet
        next if x.status.nil?

        # create a snapshot of the subscription
        package_name = x.spec.name
        catalog = x.spec.source
        channel = x.spec.channel

        package_key = "#{package_name}-#{catalog}-#{channel}"

        # retrieve the package - frist we check the cache
        package = packages[package_key]
        if package.nil?
          package = get_package_by_channel(package_name, catalog, channel)
          packages[package_key] = package
        end

        o = {
          name: x.metadata.name,
          namespace: x.metadata.namespace,
          catalog: x.spec.source,
          category: 'unknown',
          channel: x.spec.channel,
          icon: nil,
          package: package,
          keywords: [],
          package_name: x.spec.name,
          state: (x.status.state || 'unknown').downcase,
          upgrade: false,
          version: parse_version(x.status.installedCSV),
        }

        # do we have a package?
        if !package.nil?
          # do we have keywords?
          if !package.keywords.nil?
            o[:keywords] = package.keywords
          end
          # do we have a category?
          if !package.annotations.nil? && package.annotations.categories
            o[:category] = package.annotations.categories
          end
          # do we have an icon for the package?
          if !package.icon.nil? && package.icon.size > 0
            icon = package.icon.first
            if icon.mediatype == 'image/svg+xml'
              o[:icon] = icon.base64data
            end
          end
        end

        # do we have a installplan?
        unless x.status.installplan.nil?
          o[:installplan] = x.status.installplan.name
        end
        # do we have a state
        unless x.status.state.nil?
          if x.status.state == 'UpgradePending'
            o[:upgrade] = true
            o[:update] = parse_version(x.status.currentCSV)
          end
        end
        operators.push(o)
      end
    rescue Exception => e
      return "failed to retrieving the subscriptions from cluster: #{e}"
    end

    operators
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
    @client.api(API_ALPHA_V1).
      resource('installplans', namespace: namespace).
      list
  end

  # list_clusterserviceversions returns a list of clusterserviceversions
  def list_clusterserviceversions
    @client.api(API_ALPHA_V1).
      resource('clusterserviceversions').
      list
  end

  # catalog? checks the catalog exists
  def catalog?(name)
    !get_catalog(name).nil?
  end

  # package? checks the package exists
  def package?(name, channel, catalog, version: nil)
    selected = list_packages(catalog).select do |p|
      false
    end
  end

  def handle_not_found(&block)
    begin
      yield block
    rescue K8s::Error::NotFound
      nil
    end
  end

  # subscription? checks if a subscription exists
  def subscription?(namespace, name)
    begin
      @client.api(API_ALPHA_V1).
        resource('subscriptions', namespace: namespace).
        get(name)
    rescue K8s::Error::NotFound
      return false
    end
    true
  end

  # install_plan? checks is a installplan exists
  def install_plan?(namespace, name)
    begin
      @client.api(API_V1).
        resource('installplans', namespace: namespace).
        get(name)
    rescue K8s::Error::NotFound
      return false
    end
    true
  end

  # parse_version is responsible for parsing a csv version
  def parse_version(version)
    return 'unknown' if version.nil? || version.empty?

    version.split('.').drop(1).join('.')
  end
end
