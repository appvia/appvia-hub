class OperatorSubscriptionsService
  def initialize(agent)
    @agent = agent
    @cache = {}
  end

  # rubocop:disable Metrics/AbcSize
  def list
    list = []

    @agent.list_subscriptions.select(&:status).each do |x|
      package = package_cache(x)

      list.push(
        catalog: extract { x.spec.source },
        category: extract { package.annotations.categories },
        channel: extract { x.spec.channel },
        icon: extract(nil) { package.icon.first.base64data if package.icon.first.mediatype == 'image/svg+xml' },
        installplan: extract(nil) { x.status.installplan.name },
        name: extract { x.metadata.name },
        namespace: extract { x.metadata.namespace },
        package: package,
        package_name: extract { x.spec.name },
        state: extract { x.status.state.downcase },
        upgrade: extract(false) { x.status.state.casecmp('upgradepending').zero? },
        update: extract(nil) { parse_version(x.status.currentCSV) },
        version: extract { @agent.parse_version(x.status.installedCSV) }
      )
    end

    list
  end
  # rubocop:enable Metrics/AbcSize

  def get(namespace, name)
    subscription = @agent.get_subscription(namespace, name)
    raise ArgumentError, "subscription does not exist, name: #{namespace}/#{name}" if subscription.nil?

    package = @agent.get_package(
      subscription.spec.name,
      subscription.spec.source
    )
    channel = @agent.get_package_by_channel(
      subscription.spec.name,
      subscription.spec.source,
      subscription.spec.channel
    )

    {
      catalog: generate_catalog_model(package, subscription),
      channel: channel,
      info: generate_package_model(package, channel, subscription),
      package: package,
      subscription: generate_subscription_model(subscription)
    }
  end

  def approve(namespace, name)
    @agent.approve_subscription(namespace, name)
  end

  private

  def package_cache(subscription)
    package = subscription.spec.name
    catalog = subscription.spec.source
    channel = subscription.spec.channel

    key = "#{package}-#{catalog}-#{channel}"

    return @cache[key] if @cache.key?(key)

    @cache[key] = @agent.get_package_by_channel(package, catalog, channel)

    package_cache(subscription)
  end

  # generate_package_model generates a model
  # rubocop:disable Metrics/MethodLength,Metrics/AbcSize
  def generate_package_model(package, channel, subscription)
    model = {
      capabilibilities: extract { channel.annotations.capabilities.downcase },
      categories: extract { channel.annotations.categories.downcase },
      certified: extract('false') { channel.annotations.certified },
      channel_name: extract { subscription.spec.channel },
      changelog: extract([]) { JSON.parse(channel.annotations.changelog) },
      crds: [],
      full_description: extract('') { channel.description },
      icon: nil,
      name: extract('') { package.status.packageName },
      package_display_name: extract { channel.displayName },
      provider: extract('') { package.status.provider.name },
      repository: extract { channel.annotations.repository },
      short_description: extract('') { channel.annotations.description },
      upgradable: false,
      usage: {},
      version: @agent.parse_version(extract { subscription.status.installedCSV })
    }

    # do we have provider details
    state = extract { subscription.status.state.downcase }
    if state == 'upgradepending'
      model[:upgradable] = true
      model[:upgrade_version] = @agent.parse_version(extract { subscription.status.currentCSV })
    end

    model[:icon] = extract { channel.icon.first.base64data } if extract(false) { channel.icon.first.mediatype } == 'image/svg+xml'

    # do we have any own crds?
    crds = extract([]) { channel.customresourcedefinitions.owned }
    crds.each do |x|
      model[:crds].push(
        description: x.description,
        display_name: x.displayName,
        kind: x.kind,
        name: x.name,
        version: x.version
      )
    end

    # do we have examples?
    (extract('[]') { JSON.parse(channel.annotations['alm-examples']) }).each do |x|
      model[:usage][x['kind']] = x.to_yaml
    end

    model
  end
  # rubocop:enable Metrics/MethodLength,Metrics/AbcSize

  # generate_subscription_model creates a model for the subscription
  def generate_subscription_model(subscription)
    model = {
      approvals: extract { subscription.spec.installPlanApproval.downcase },
      name: subscription.metadata.name,
      namespace: subscription.metadata.namespace,
      installplan: extract { subscription.status.installplan.name },
      running: 'unknown'
    }
    # check if the pod is running
    state = extract('') { subscription.status.state.downcase }
    model[:running] = 'running' if %w[atlatestknown upgradepending].include?(state)

    model
  end

  # generate_catalog_model creates a model for the catalog
  def generate_catalog_model(package, subscription)
    catalog = {
      display_name: extract { package.status.catalogSourceDisplayName },
      healthy: true,
      namespace: extract { package.status.catalogSourceNamespace },
      publisher: extract { package.status.catalogSourcePublisher },
      source: extract { package.status.catalogSource }
    }

    status = subscription.status
    return catalog if status.nil?

    (extract([]) { status.catalogHealth }).each do |x|
      next unless extract { x.catalogSourceRef.name } == subscription.spec.source

      catalog[:healthy] = extract(false) { x.healthy }
      catalog[:last_sync] = extract { x.lastUpdated }
    end

    catalog
  end

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
end
