require 'rails_helper'

RSpec.describe ProjectResourcesBootstrapService, type: :service do
  include_context 'time helpers'

  let :resource_provisioning_service do
    instance_double('ResourceProvisioningService')
  end

  let!(:user) { create :user }

  let!(:project) { create :project }

  subject do
    described_class.new(
      project,
      resource_provisioning_service: resource_provisioning_service
    )
  end

  describe '#bootstrap' do
    context 'when project has some resources already' do
      before do
        integration = create_mocked_integration
        create :code_repo, project: project, integration: integration

        expect(resource_provisioning_service).to receive(:request_create).never
      end

      it 'does not provision any resources' do
        expect do
          expect(subject.bootstrap(requested_by: user)).to be false
        end.not_to change(Resource, :count)
      end

      it 'does not log an audit' do
        expect do
          subject.bootstrap(requested_by: user)
        end.not_to change(project.audits, :count)
      end
    end

    context 'when project has no resources yet' do
      context 'when no integrations are configured yet' do
        before do
          expect(resource_provisioning_service).to receive(:request_create).never
        end

        it 'does not provision any resources' do
          expect do
            expect(subject.bootstrap(requested_by: user)).to be false
          end.not_to change(Resource, :count)
        end

        it 'does not log an audit' do
          expect do
            subject.bootstrap(requested_by: user)
          end.not_to change(project.audits, :count)
        end
      end

      context 'when at least some integrations are configured' do
        before do
          create_mocked_integration(provider_id: 'git_hub')
          create_mocked_integration(provider_id: 'quay')

          expect(resource_provisioning_service).to receive(:request_create)
            .exactly(2)
            .times
        end

        it 'provisions a GitHub code repo and Quay Docker repo' do
          expect(Resources::CodeRepo.count).to be 0
          expect(Resources::DockerRepo.count).to be 0
          expect(Resources::KubeNamespace.count).to be 0

          expect do
            expect(subject.bootstrap(requested_by: user).length).to be 2
          end.to change(Resource, :count).by(2)

          expect(Resources::CodeRepo.count).to be 1
          expect(Resources::DockerRepo.count).to be 1
          expect(Resources::KubeNamespace.count).to be 0
        end

        it 'logs an audit for project_resources_bootstrap' do
          expect do
            subject.bootstrap(requested_by: user)
          end.to change(project.audits, :count).by(1)

          audit = project.audits.order(:created_at).last
          expect(audit.action).to eq 'project_resources_bootstrap'
          expect(audit.created_at.to_i).to eq now.to_i
        end
      end
    end
  end
end
