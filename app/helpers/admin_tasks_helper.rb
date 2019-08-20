module AdminTasksHelper
  ADMIN_TASK_STATUS_TO_CLASS = {
    'pending' => 'secondary',
    'running' => 'warning',
    'completed' => 'success',
    'failed' => 'danger'
  }.freeze

  def admin_task_status_badge(status, css_class: [])
    tag.span status,
      class: [
        'badge',
        "badge-#{ADMIN_TASK_STATUS_TO_CLASS[status]}",
        'text-capitalize'
      ] + Array(css_class)
  end

  # rubocop:disable Metrics/MethodLength
  def admin_task_integrations(task)
    return [] if task.integrations.blank?

    kube_integration = Integration.find_by id: task.integrations['kubernetes']
    grafana_integration = Integration.find_by id: task.integrations['grafana']
    loki_integration = Integration.find_by id: task.integrations['loki']
    service_broker_integration = Integration.find_by id: task.integrations['service_broker']

    [
      {
        type: 'Kubernetes',
        integration: kube_integration,
        name: kube_integration&.name,
        path: kube_integration.present? ? admin_integrations_path_with_selected(kube_integration) : nil
      },
      {
        type: 'Grafana',
        integration: grafana_integration,
        name: grafana_integration&.name,
        path: grafana_integration.present? ? admin_integrations_path_with_selected(grafana_integration) : nil
      },
      {
        type: 'Loki',
        integration: loki_integration,
        name: loki_integration&.name,
        path: loki_integration.present? ? admin_integrations_path_with_selected(loki_integration) : nil
      },
      {
        type: 'Service Broker',
        integration: service_broker_integration,
        name: service_broker_integration&.name,
        path: service_broker_integration.present? ? admin_integrations_path_with_selected(service_broker_integration) : nil
      }
    ]
  end
  # rubocop:enable Metrics/MethodLength

  def admin_task_config_data_panels(task)
    init_secret_fields = task
      .cluster_creator_spec['init_options']['properties']
      .each_with_object([]) do |(k, v), acc|
        acc << k if v['secret'] == true
      end

    init_options_cleaned = task
      .init_options
      .dup
      .map do |k, v|
        [
          k,
          init_secret_fields.include?(k) ? '[REDACTED]' : v
        ]
      end
      .to_h

    [
      {
        id: "init-options-#{task.id}",
        text: 'Account access config',
        data: init_options_cleaned
      },
      {
        id: "provision-options-#{task.id}",
        text: 'Cluster config',
        data: task.provision_options
      }
    ]
  end

  def delete_admin_task_link(task, css_class: nil)
    link_to 'Delete',
      admin_task_path(task),
      method: :delete,
      class: css_class,
      data: {
        confirm: 'Are you sure you want to delete this task permanently?',
        title: 'Delete task',
        verify: 'yes',
        verify_text: "Type 'yes' to confirm"
      },
      role: 'button'
  end

  def split_provision_options_property_spec(property_spec)
    required = Array(property_spec['required'])

    default = {
      'required' => [],
      'properties' => {}
    }

    advanced = {
      'required' => [],
      'properties' => {}
    }

    property_spec['properties'].each do |k, v|
      group = v['tag'] == 'default' ? default : advanced

      group['properties'][k] = v
      group['required'] << k if required.include?(k)
    end

    [
      default,
      advanced
    ]
  end
end
