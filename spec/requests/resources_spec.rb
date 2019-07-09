require 'rails_helper'

RSpec.describe 'Project resources', type: :request do
  include_context 'time helpers'

  before do
    @project = create :project
  end

  shared_examples 'fails when resource type is invalid' do
    context 'when resource type is not set' do
      let(:resource_type) { nil }

      it 'redirects to the home page with an error flash message' do
        make_request
        expect(response).to redirect_to(root_path)
        expect(flash[:error]).not_to be_empty
      end
    end

    context 'when resource type is set but not a valid identifier' do
      let(:resource_type) { 'InvalidType' }

      it 'returns a 422 Unprocessable Entity' do
        make_request
        expect(response).not_to be_successful
        expect(response).to have_http_status(422)
      end
    end
  end

  shared_examples 'fails when no integrations are available for the resource type' do
    context 'when no integrations are available for the resource type' do
      it 'redirects to the home page with an error flash message' do
        make_request
        expect(response).to redirect_to(root_path)
        expect(flash[:warning]).not_to be_empty
      end
    end
  end

  describe 'new - GET /spaces/:project_id/resources/new' do
    it_behaves_like 'unauthenticated not allowed' do
      before do
        get new_project_resource_path(@project)
      end
    end

    it_behaves_like 'authenticated' do
      let :make_request do
        get new_project_resource_path(@project, type: resource_type)
      end

      include_examples 'fails when resource type is invalid'

      context 'with a valid resource type' do
        let(:resource_type) { 'CodeRepo' }

        include_examples 'fails when no integrations are available for the resource type'

        context 'with at least one integration available for the resource type' do
          let! :integration do
            create_mocked_integration provider_id: 'git_hub'
          end

          it 'loads the new resource page' do
            make_request
            expect(response).to be_successful
            expect(response).to render_template(:new)
            expect(assigns(:project)).to eq @project
            expect(assigns(:resource_type)[:id]).to eq 'CodeRepo'
            expect(assigns(:integrations)).to eq [integration]
            expect(assigns(:resource)).to be_a Resource
            expect(assigns(:resource)).to be_new_record
          end
        end
      end
    end
  end

  describe 'create - POST /spaces/:project_id/resources' do
    let :params do
      {
        name: 'Foo'
      }
    end

    it_behaves_like 'unauthenticated not allowed' do
      before do
        post project_resources_path(@project), params: { resource: params }
      end
    end

    it_behaves_like 'authenticated' do
      let :make_request do
        post project_resources_path(@project, type: resource_type), params: { resource: params }
      end

      include_examples 'fails when resource type is invalid'

      context 'with a valid resource type' do
        let(:resource_type) { 'CodeRepo' }

        include_examples 'fails when no integrations are available for the resource type'

        context 'with at least one integration available for the resource type' do
          let! :integration do
            create_mocked_integration provider_id: 'git_hub'
          end

          context 'with valid params' do
            let :params do
              {
                type: 'Resources::CodeRepo',
                integration_id: integration.id,
                name: 'foo'
              }
            end

            before do
              resource_provisioning_service = instance_double('ResourceProvisioningService')
              expect(ResourceProvisioningService).to receive(:new)
                .and_return(resource_provisioning_service)
              expect(resource_provisioning_service).to receive(:request_create)
            end

            it 'creates a new Resource with the given params, requests creation and redirects to the project page' do
              expect do
                make_request
                expect(response).to redirect_to(project_path(@project, autorefresh: true))
                resource = assigns(:resource)
                expect(resource).to be_persisted
                expect(resource).to be_a Resources::CodeRepo
                expect(resource.integration).to eq integration
                expect(resource.name).to eq params[:name]
                expect(resource.created_at.to_i).to eq now.to_i
              end.to change { Resource.count }.by(1)
            end

            it 'logs an Audit' do
              make_request
              resource = assigns(:resource)
              audit = resource.audits.order(:created_at).last
              expect(audit.action).to eq 'create'
              expect(audit.user_email).to eq auth_email
              expect(audit.created_at.to_i).to eq now.to_i
            end
          end

          context 'with invalid params' do
            let :params do
              {
                type: 'Resources::CodeRepo',
                integration_id: nil,
                name: 'Invalid Name'
              }
            end

            before do
              expect(ResourceProvisioningService).to receive(:new).never
            end

            it 'loads the new page with errors' do
              make_request
              expect(response).to be_successful
              expect(response).to render_template(:new)
              resource = assigns(:resource)
              expect(resource).not_to be_persisted
              expect(resource.errors).to_not be_empty
              expect(resource.errors[:integration]).to be_present
              expect(resource.errors[:name]).to be_present
            end
          end
        end
      end
    end
  end

  describe 'destroy - DELETE /spaces/:project_id/resources/:id' do
    let(:integration) { create_mocked_integration }

    let! :resource do
      create :code_repo, project: @project, integration: integration
    end

    let :resource_provisioning_service do
      instance_double('ResourceProvisioningService')
    end

    before do
      allow(ResourceProvisioningService).to receive(:new)
        .and_return(resource_provisioning_service)
    end

    it_behaves_like 'unauthenticated not allowed' do
      before do
        expect(resource_provisioning_service).to receive(:request_delete).never
        delete project_resource_path(@project, resource)
      end
    end

    it_behaves_like 'authenticated' do
      it 'requests deletion of the resource' do
        expect(resource_provisioning_service).to receive(:request_delete)
          .with(resource)

        expect do
          delete project_resource_path(@project, resource)
        end.not_to change(Resource, :count)

        expect(response).to redirect_to(project_path(@project, autorefresh: true))
      end
    end
  end

  describe 'prepare_bootstrap - GET /spaces/:project_id/resources/bootstrap' do
    it_behaves_like 'unauthenticated not allowed' do
      before do
        get bootstrap_project_resources_path(@project)
      end
    end

    it_behaves_like 'authenticated' do
      context 'when project already has resources' do
        before do
          integration = create_mocked_integration
          create :code_repo, project: @project, integration: integration
        end

        it 'calls the ProjectResourcesBootstrapService as expected but redirects back to home' do
          get bootstrap_project_resources_path(@project)
          expect(response).to redirect_to(root_path)
          expect(flash[:warning]).not_to be_empty
        end
      end

      context 'when project has no resources' do
        it 'calls the ProjectResourcesBootstrapService as expected and loads the page' do
          get bootstrap_project_resources_path(@project)
          expect(response).to be_successful
          expect(response).to render_template(:prepare_bootstrap)
          expect(assigns(:prepare_results)).to be_present
        end
      end
    end
  end

  describe 'bootstrap - POST /spaces/:project_id/resources/bootstrap' do
    it_behaves_like 'unauthenticated not allowed' do
      before do
        post bootstrap_project_resources_path(@project)
      end
    end

    it_behaves_like 'authenticated' do
      before do
        project_bootstrap_service = instance_double('ProjectResourcesBootstrapService')
        expect(ProjectResourcesBootstrapService).to receive(:new)
          .with(@project)
          .and_return(project_bootstrap_service)
        expect(project_bootstrap_service).to receive(:bootstrap)
      end

      it 'calls the ProjectResourcesBootstrapService as expected and redirects to the project page' do
        post bootstrap_project_resources_path(@project)
        expect(response).to redirect_to(@project)
      end
    end
  end
end
