module Admin
  class TaskWorker
    include Sidekiq::Worker

    sidekiq_options queue: 'admin_tasks'

    # rubocop:disable Metrics/BlockLength
    HANDLERS = {
      'Admin::Tasks::CreateKubeCluster' => lambda do |task|
        init_options = task
          .init_options
          .deep_dup
          .merge(provider: task.cluster_creator)
          .with_indifferent_access
        agent = HubClustersCreator.new(init_options)

        provision_options = task
          .provision_options
          .deep_dup
          .with_indifferent_access

        results = agent.provision provision_options

        cluster_name = provision_options['name']

        kube_integration = Integration.create!(
          provider_id: 'kubernetes',
          name: "#{cluster_name} cluster on #{task.cluster_creator.upcase}",
          config: {
            'cluster_name' => cluster_name,
            'api_url' => results[:cluster][:endpoint],
            'ca_cert' => results[:cluster][:ca],
            'token' => results[:cluster][:service_account_token],
            'global_service_account_name' => results[:cluster][:global_service_account_name],
            'global_service_account_token' => results[:cluster][:global_service_account_token]
          }
        )

        grafana_url = results[:services][:grafana][:url]

        grafana_integration = Integration.create!(
          provider_id: 'grafana',
          parent_ids: [kube_integration.id],
          name: "Grafana for #{kube_integration.name}",
          config: {
            'url' => grafana_url,
            'api_key' => results[:services][:grafana][:api_key],
            'ca_cert' => 'noop',
            'template_url' => 'http://s3-eu-west-2.amazonaws.com/appvia-hub-demo-grafana-templates-store/kubernetes-prometheus.json.tmpl'
          }
        )

        loki_integration = Integration.create!(
          provider_id: 'loki',
          parent_ids: [kube_integration.id],
          name: "Loki for #{kube_integration.name}",
          config: {
            'grafana_url' => grafana_url,
            'data_source_name' => 'Loki'
          }
        )

        task.update!(
          integrations: {
            'kubernetes' => kube_integration.id,
            'grafana' => grafana_integration.id,
            'loki' => loki_integration.id
          }
        )

        true
      end
    }.freeze
    # rubocop:enable Metrics/BlockLength

    def perform(task_id)
      with_task(task_id) do |task|
        with_handler(task) do |handler|
          task.update!(
            status: Admin::Task.statuses[:running],
            started_at: Time.current
          )

          result = handler.call task

          task.update!(
            status: result ? Admin::Task.statuses[:completed] : Admin::Task.statuses[:failed],
            finished_at: Time.current
          )
        rescue StandardError => e
          logger.error [
            "Failed to process admin task #{task.id} (type: #{task.type})",
            "- error: #{e.inspect}"
          ].join(' ')

          task.update!(
            status: Admin::Task.statuses[:failed],
            error: e.message,
            finished_at: Time.current
          )
        end
      end
    end

    private

    def with_task(id)
      task = Admin::Task.find_by id: id

      if task
        yield task
      else
        logger.error "Could not find admin task with ID: #{id}"
      end
    end

    def with_handler(task)
      handler = HANDLERS[task.type]

      if handler
        yield handler
      else
        logger.error "No handler found for admin task type: #{task.type}"
      end
    end
  end
end
