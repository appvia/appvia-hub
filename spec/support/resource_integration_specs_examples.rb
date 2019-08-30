module ResourceIntegrationSpecsExamples
  RSpec.shared_examples 'resource integration specs' do
    include_context 'time helpers'

    let! :integration do
      parent_ids = if defined?(parent_integration)
                     [parent_integration.id]
                   else
                     []
                   end

      create :integration,
        provider_id: provider_id,
        config: integration_config,
        parent_ids: parent_ids
    end

    let! :provisioning_service do
      ResourceProvisioningService.new
    end

    let :agent do
      instance_double(agent_class)
    end

    before do
      expect(agent_class).to receive(:new)
        .with(**agent_initializer_params)
        .and_return(agent)

      allow(ResourceProvisioningService).to receive(:new)
        .and_return(provisioning_service)
    end

    let :dependents do
      # Example:
      #
      # [
      #   {
      #      type: 'Foo',
      #      integration: '<instance of Integration for this dependent>',
      #      factory: :foo
      #   }
      # ]

      []
    end

    describe 'request create' do
      context 'when agent doesn\'t throw an error' do
        before do
          agent_create_method_call_success.call(agent, resource)

          dependents.each do |d|
            expect(provisioning_service).to receive(:request_dependent_create)
              .with(resource, d[:type])
              .and_call_original

            expect(DependentIntegrationsService).to receive(:find_dependent_for)
              .with(integration, d[:type])
              .and_call_original
          end
        end

        it 'works as expected' do
          move_time_to 1.minute.from_now

          expect do
            provisioning_service.request_create resource
          end.to change(Resources::RequestCreateWorker.jobs, :size).by(1)

          expect(resource.status).to eq Resource.statuses[:pending]

          expect(resource.audits.order(:created_at).last.action).to eq 'request_create'

          move_time_to 1.minute.from_now

          Resources::RequestCreateWorker.perform_one

          updated = Resource.find resource.id

          expect(updated.name).to eq resource.name
          expect(updated.status).to eq Resource.statuses[:active]

          request_create_finished_success_expectations.call updated

          if dependents.any?
            expect(updated.children.length).to eq dependents.size

            expect(Resources::RequestCreateWorker.jobs.size).to eq dependents.size

            dependents.each_with_index do |d, ix|
              worker = Resources::RequestCreateWorker.jobs[ix]

              dependent_resource = updated.children.where(type: "Resources::#{d[:type]}").first

              expect(worker['args']).to contain_exactly dependent_resource.id

              expect(dependent_resource.integration).to eq d[:integration]
              expect(dependent_resource.project).to eq resource.project
              expect(dependent_resource.name).to eq resource.name
              expect(dependent_resource.status).to eq Resource.statuses[:pending]

              expect(dependent_resource.audits.order(:created_at).last.action).to eq 'request_create'
            end
          end
        end
      end

      context 'when agent throws an error' do
        before do
          agent_create_method_call_error.call(agent, resource)

          expect(provisioning_service).to receive(:request_dependent_create).never if dependents.any?
        end

        it 'marks the resource as failed' do
          provisioning_service.request_create resource

          Resources::RequestCreateWorker.perform_one

          updated = Resource.find resource.id

          expect(updated.name).to eq resource.name
          expect(updated.status).to eq Resource.statuses[:failed]

          request_create_finished_error_expectations.call updated
        end
      end
    end

    describe 'request_delete' do
      before do
        request_delete_before_setup_resource_state.call resource
        resource.status = Resource.statuses[:active]
        resource.save!

        dependents.each do |d|
          create d[:factory],
            integration: d[:integration],
            parent: resource
        end
      end

      context 'when agent doesn\'t throw an error' do
        before do
          agent_delete_method_call_success.call(agent, resource)
        end

        it 'works as expected' do
          move_time_to 1.minute.from_now

          expect do
            provisioning_service.request_delete resource
          end.to change(Resources::RequestDeleteWorker.jobs, :size).by(1)

          expect(resource.status).to eq Resource.statuses[:deleting]

          expect(resource.audits.order(:created_at).last.action).to eq 'request_delete'

          move_time_to 1.minute.from_now

          Resources::RequestDeleteWorker.perform_one

          expect(Resource.exists?(resource.id)).to be false

          if dependents.any?
            expect(Resources::RequestDeleteWorker.jobs.size).to eq dependents.size

            dependent_resources = resource.children.entries
            expect(dependent_resources.size).to eq dependents.size

            worker_args = Resources::RequestDeleteWorker.jobs.map { |j| j['args'] }

            expect(worker_args).to match_array(
              dependent_resources.map { |r| [r.id] }
            )

            expect(dependent_resources.map(&:status).uniq).to contain_exactly Resource.statuses[:deleting]

            dependent_resources.each do |r|
              expect(r.audits.order(:created_at).last.action).to eq 'request_delete'
            end
          end
        end
      end

      context 'when agent throws an error' do
        before do
          agent_delete_method_call_error.call(agent, resource)
        end

        it 'marks the resource as failed' do
          provisioning_service.request_delete resource

          Resources::RequestDeleteWorker.perform_one

          updated = Resource.find resource.id

          expect(updated.status).to eq Resource.statuses[:failed]

          if dependents.any?
            expect(Resources::RequestDeleteWorker.jobs.size).to eq 0
            expect(resource.children.size).to eq dependents.size
          end
        end
      end
    end
  end
end
