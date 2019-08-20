require 'k8s-client'

class ServiceBrokerAgent
  API_VERSION = 'servicecatalog.k8s.io/v1beta1'.freeze

  PROVISION_WAIT_ATTEMPTS = 20
  PROVISION_WAIT_CHECK_TIMEOUT = 30.seconds.to_i
  PROVISION_WAIT_DELAY = 20.seconds.to_i

  def initialize(kube_api_url:, kube_ca_cert:, kube_token:)
    options = {
      ssl_verify_peer: false
    }
    config = K8s::Config.new(
      clusters: [{
        name: 'default',
        cluster: {
          server: kube_api_url,
          certificate_authority_data: kube_ca_cert
        }
      }],
      users: [{
        name: 'default',
        user: {
          token: kube_token,
          client_certificate_data: kube_ca_cert
        }
      }],
      contexts: [{
        name: 'default',
        context: { cluster: 'default', user: 'default' }
      }],
      current_context: 'default'
    )
    @client = K8s::Client.config(config, options)
  end

  # rubocop:disable Naming/AccessorMethodName
  def get_options
    classes = @client.api(API_VERSION).resource('clusterserviceclasses').list
    plans = @client.api(API_VERSION).resource('clusterserviceplans').list
    classes.each do |c|
      c.plans = plans.select { |p| p[:spec][:clusterServiceClassRef][:name] == c[:metadata][:name] }
    end
  end
  # rubocop:enable Naming/AccessorMethodName

  def create_resource(namespace:, cluster_service_class_external_name:, cluster_service_plan_external_name:, name:, parameters:)
    instance = create_instance(
      namespace: namespace,
      cluster_service_class_external_name: cluster_service_class_external_name,
      cluster_service_plan_external_name: cluster_service_plan_external_name,
      name: name,
      parameters: parameters
    )
    create_binding(namespace: namespace, service_instance_name: name)

    setup_wait.until do
      instance = get_instances(namespace).find { |i| i[:metadata][:name] == name }
      binding = instance[:bindings].find { |b| b[:metadata][:name] == name }
      # wait for instance provisioned and binding ready, or timeout and fail
      instance_ready = instance[:status][:provisionStatus] == 'Provisioned'
      binding_ready = binding[:status][:conditions].find { |c| c[:reason] == 'InjectedBindResult' && c[:type] == 'Ready' && c[:status] == 'True' }
      instance_ready.present? && binding_ready.present?
    end
    instance
  end

  def delete_resource(namespace:, name:)
    delete_binding(namespace: namespace, service_binding_name: name)
    delete_instance(namespace: namespace, service_instance_name: name)

    instance = get_instances(namespace).find { |i| i[:metadata][:name] == name }
    return true if instance.nil?

    setup_wait.until do
      instance = get_instances(namespace).find { |i| i[:metadata][:name] == name }
      instance.nil?
    end
    instance.nil?
  end

  private

  def setup_wait
    Wait.new(
      attempts: PROVISION_WAIT_ATTEMPTS,
      timeout: PROVISION_WAIT_CHECK_TIMEOUT,
      delay: PROVISION_WAIT_DELAY,
      debug: Rails.env.development?
    )
  end

  def get_instances(namespace)
    instances = @client.api(API_VERSION).resource('serviceinstances', namespace: namespace).list
    bindings = @client.api(API_VERSION).resource('servicebindings', namespace: namespace).list

    instances.each do |i|
      i.bindings = bindings.select { |b| b[:spec][:instanceRef][:name] == i[:metadata][:name] }
    end
  end

  def create_instance(namespace:, cluster_service_class_external_name:, cluster_service_plan_external_name:, name:, parameters:)
    instance = K8s::Resource.new(
      apiVersion: API_VERSION,
      kind: 'ServiceInstance',
      metadata: {
        namespace: namespace,
        name: name
      },
      spec: {
        clusterServiceClassExternalName: cluster_service_class_external_name,
        clusterServicePlanExternalName: cluster_service_plan_external_name,
        parameters: parameters
      }
    )

    @client.api(API_VERSION).resource('serviceinstances', namespace: namespace).create_resource(instance)
  end

  def create_binding(namespace:, service_instance_name:)
    binding = K8s::Resource.new(
      apiVersion: API_VERSION,
      kind: 'ServiceBinding',
      metadata: {
        namespace: namespace,
        name: service_instance_name
      },
      spec: {
        instanceRef: {
          name: service_instance_name
        }
      }
    )

    @client.api(API_VERSION).resource('servicebindings', namespace: namespace).create_resource(binding)
  end

  def delete_instance(namespace:, service_instance_name:)
    @client.api(API_VERSION).resource('serviceinstances', namespace: namespace).delete(service_instance_name)
  rescue K8s::Error::NotFound
    Rails.logger.warn [
      '[ServiceBroker Agent]',
      'cannot delete serviceinstance:',
      service_instance_name,
      'because it does not exist'
    ].join(' ')
    true
  end

  def delete_binding(namespace:, service_binding_name:)
    @client.api(API_VERSION).resource('servicebindings', namespace: namespace).delete(service_binding_name)
  rescue K8s::Error::NotFound
    Rails.logger.warn [
      '[ServiceBroker Agent]',
      'cannot delete servicebinding:',
      service_binding_name,
      'because it does not exist'
    ].join(' ')
    true
  end
end
