require 'rails_helper'

RSpec.describe 'Project resources', type: :request do
  include_context 'time helpers'

  before do
    @project = create :project

    # Create some other projects to ensure we have a broader pool of data
    @other_projects = create_list :project, 2
    @other_teams = @other_projects.map(&:team)
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
      it 'redirects to the home page with a warning flash message' do
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
      def expect_new_resource_page(project, resource_type, integration)
        expected_integrations = {
          integration.provider['name'] => [integration]
        }

        get new_project_resource_path(project, type: resource_type)
        expect(response).to be_successful
        expect(response).to render_template(:new)
        expect(assigns(:project)).to eq project
        expect(assigns(:resource_type)[:id]).to eq 'CodeRepo'
        expect(assigns(:integrations)).to eq expected_integrations
        expect(assigns(:resource)).to be_a Resource
        expect(assigns(:resource)).to be_new_record
      end

      def expect_access_denied(project, resource_type)
        get new_project_resource_path(project, type: resource_type)
        expect(response).to redirect_to root_path
        expect(flash[:alert]).not_to be_empty
      end

      it_behaves_like 'a hub admin' do
        # Used in the shared examples called below
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
              expect_new_resource_page @project, resource_type, integration
            end
          end
        end
      end

      context 'not a hub admin' do
        context 'with a valid resource type and at least on integration for the resource type' do
          let(:resource_type) { 'CodeRepo' }

          let! :integration do
            create_mocked_integration provider_id: 'git_hub'
          end

          it 'can\'t load the new resource page for the project' do
            expect_access_denied @project, resource_type
          end

          context 'is in the project\'s team' do
            before do
              create :team_membership, team: @project.team, user: current_user
            end

            it 'loads the new resource page' do
              expect_new_resource_page @project, resource_type, integration
            end
          end

          context 'is in a different team' do
            let(:other_project) { @other_projects.first }
            let(:other_team) { other_project.team }

            before do
              create :team_membership, team: other_team, user: current_user
            end

            it 'can\'t load the new resource page for the project' do
              expect_access_denied @project, resource_type
            end

            it 'can still load the new resource page for a project in this different team' do
              expect_new_resource_page other_project, resource_type, integration
            end
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
      def expect_project_create(project, resource_type, integration, params)
        resource_provisioning_service = instance_double('ResourceProvisioningService')
        expect(ResourceProvisioningService).to receive(:new)
          .and_return(resource_provisioning_service)
        expect(resource_provisioning_service).to receive(:request_create)

        expect do
          post project_resources_path(project, type: resource_type), params: { resource: params }
        end.to change { Resource.count }.by(1)

        expect(response).to redirect_to(project_path(project, autorefresh: true))

        resource = assigns(:resource)
        expect(resource).to be_persisted
        expect(resource).to be_a Resources::CodeRepo
        expect(resource.integration).to eq integration
        expect(resource.requested_by).to eq current_user
        expect(resource.name).to eq params[:name]
        expect(resource.created_at.to_i).to eq now.to_i
        expect(resource.template_url).to eq params[:git_hub][:template_url]

        audit = resource.audits.order(:created_at).last
        expect(audit.action).to eq 'create'
        expect(audit.associated).to eq project
        expect(audit.user_email).to eq auth_email
        expect(audit.created_at.to_i).to eq now.to_i
      end

      def expect_access_denied(project, resource_type, params)
        expect do
          post project_resources_path(project, type: resource_type), params: { resource: params }
        end.not_to change(Resource, :count)
        expect(response).to redirect_to root_path
        expect(flash[:alert]).not_to be_empty
      end

      it_behaves_like 'a hub admin' do
        # Used in the shared examples called below
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
                  type: "Resources::#{resource_type}",
                  integration_id: integration.id,
                  name: 'foo',
                  git_hub: {
                    template_url: 'template_url'
                  }
                }
              end

              it 'creates a new resource with the given params, requests creation, logs an audit and redirects to the project page' do
                expect_project_create @project, resource_type, integration, params
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
                expect do
                  make_request
                end.not_to change(Resource, :count)

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

      context 'not a hub admin' do
        context 'with a valid resource type and at least on integration for the resource type' do
          let(:resource_type) { 'CodeRepo' }

          let! :integration do
            create_mocked_integration provider_id: 'git_hub'
          end

          let :params do
            {
              type: "Resources::#{resource_type}",
              integration_id: integration.id,
              name: 'foo',
              git_hub: {
                template_url: 'template_url'
              }
            }
          end

          it 'can\'t create a resource within the specified project' do
            expect_access_denied @project, resource_type, params
          end

          context 'is in the project\'s team' do
            before do
              create :team_membership, team: @project.team, user: current_user
            end

            it 'creates a new resource with the given params, requests creation, logs an audit and redirects to the project page' do
              expect_project_create @project, resource_type, integration, params
            end
          end

          context 'is in a different team' do
            let(:other_project) { @other_projects.first }
            let(:other_team) { other_project.team }

            before do
              create :team_membership, team: other_team, user: current_user
            end

            it 'can\'t create a resource within the specified project' do
              expect_access_denied @project, resource_type, params
            end

            it 'can still load the new resource page for a project in this different team' do
              expect_project_create other_project, resource_type, integration, params
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
      it_behaves_like 'not a hub admin so not allowed' do
        before do
          delete project_resource_path(@project, resource)
        end
      end

      def expect_resource_deletion_request(resource)
        expect(resource_provisioning_service).to receive(:request_delete)
          .with(resource)

        expect do
          delete project_resource_path(resource.project, resource)
        end.not_to change(Resource, :count)

        expect(response).to redirect_to(project_path(resource.project, autorefresh: true))
      end

      def expect_access_denied(resource)
        expect(resource_provisioning_service).to receive(:request_delete)
          .with(resource)
          .never
        delete project_resource_path(resource.project, resource)
        expect(response).to redirect_to root_path
        expect(flash[:alert]).not_to be_empty
        expect(Resource.find(resource.id)).not_to eq Resource.statuses[:deleting]
      end

      it_behaves_like 'a hub admin' do
        it 'requests deletion of the resource' do
          expect_resource_deletion_request resource
        end

        context 'with mismatched project and resource provided' do
          it 'raises a RecordNotFound error' do
            expect do
              delete project_resource_path(@other_projects.first, resource)
            end.to raise_error(ActiveRecord::RecordNotFound)
            expect(Resource.find(resource.id)).not_to eq Resource.statuses[:deleting]
          end
        end
      end

      context 'not a hub admin' do
        context 'is in the project\'s team' do
          before do
            create :team_membership, team: @project.team, user: current_user
          end

          it 'requests deletion of the resource' do
            expect_resource_deletion_request resource
          end
        end

        context 'is in a different team' do
          let(:other_project) { @other_projects.first }
          let(:other_team) { other_project.team }

          before do
            create :team_membership, team: other_team, user: current_user
          end

          it 'can\'t request deletion of a resource within the specified project' do
            expect_access_denied resource
          end

          it 'can still request deletion of a resource in this different project' do
            resource = create :code_repo, project: other_project, integration: integration
            expect_resource_deletion_request resource
          end
        end
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
      it_behaves_like 'not a hub admin so not allowed' do
        before do
          expect(ProjectResourcesBootstrapService).to receive(:new).never
          get bootstrap_project_resources_path(@project)
        end
      end

      def expect_prepare_bootstrap_page(project)
        get bootstrap_project_resources_path(project)
        expect(response).to be_successful
        expect(response).to render_template(:prepare_bootstrap)
        expect(assigns(:prepare_results)).to be_present
      end

      def expect_access_denied(project)
        expect(ProjectResourcesBootstrapService).to receive(:new).never
        get bootstrap_project_resources_path(project)
        expect(response).to redirect_to root_path
        expect(flash[:alert]).not_to be_empty
      end

      it_behaves_like 'a hub admin' do
        context 'when project already has resources' do
          before do
            integration = create_mocked_integration
            create :code_repo, project: @project, integration: integration
          end

          it 'redirects back to home' do
            get bootstrap_project_resources_path(@project)
            expect(response).to redirect_to(root_path)
            expect(flash[:warning]).not_to be_empty
          end
        end

        context 'when project has no resources' do
          it 'loads the prepare_bootstrap page' do
            expect_prepare_bootstrap_page @project
          end
        end
      end

      context 'not a hub admin' do
        context 'is in the project\'s team' do
          before do
            create :team_membership, team: @project.team, user: current_user
          end

          it 'loads the prepare_bootstrap page' do
            expect_prepare_bootstrap_page @project
          end
        end

        context 'is in a different team' do
          let(:other_project) { @other_projects.first }
          let(:other_team) { other_project.team }

          before do
            create :team_membership, team: other_team, user: current_user
          end

          it 'can\'t load the prepare_bootstrap page for the project' do
            expect_access_denied @project
          end

          it 'can still load the prepare_bootstrap page for this different project' do
            expect_prepare_bootstrap_page other_project
          end
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
      it_behaves_like 'not a hub admin so not allowed' do
        before do
          expect(ProjectResourcesBootstrapService).to receive(:new).never
          post bootstrap_project_resources_path(@project)
        end
      end

      def expect_bootstrap(project)
        project_bootstrap_service = instance_double('ProjectResourcesBootstrapService')
        expect(ProjectResourcesBootstrapService).to receive(:new)
          .with(project)
          .and_return(project_bootstrap_service)
        expect(project_bootstrap_service).to receive(:bootstrap)
          .with(requested_by: current_user)

        post bootstrap_project_resources_path(project)
        expect(response).to redirect_to(project_path(project, autorefresh: true))
      end

      def expect_access_denied(project)
        expect(ProjectResourcesBootstrapService).to receive(:new).never
        get bootstrap_project_resources_path(project)
        expect(response).to redirect_to root_path
        expect(flash[:alert]).not_to be_empty
      end

      it_behaves_like 'a hub admin' do
        it 'bootstraps resources and redirects to the project page' do
          expect_bootstrap @project
        end
      end

      context 'not a hub admin' do
        context 'is in the project\'s team' do
          before do
            create :team_membership, team: @project.team, user: current_user
          end

          it 'bootstraps resources and redirects to the project page' do
            expect_bootstrap @project
          end
        end

        context 'is in a different team' do
          let(:other_project) { @other_projects.first }
          let(:other_team) { other_project.team }

          before do
            create :team_membership, team: other_team, user: current_user
          end

          it 'can\'t boostrap resources for the project' do
            expect_access_denied @project
          end

          it 'can still bootstrap resources for this different project' do
            expect_bootstrap other_project
          end
        end
      end
    end
  end

  describe 'checks - GET /spaces/:project_id/resources/:id/checks' do
    let(:integration) { create_mocked_integration }

    let! :resource do
      create :code_repo, project: @project, integration: integration
    end

    let :resource_checks do
      [{
        colour: 'success',
        text: 'ci/circleci: test Your tests passed on CircleCI!',
        status: 'SUCCESS',
        url: false
      }]
    end

    let :resource_checks_service do
      instance_double('ResourceChecksService')
    end

    before do
      allow(ResourceChecksService).to receive(:new)
        .and_return(resource_checks_service)
      allow(resource_checks_service).to receive(:get_checks)
        .and_return(resource_checks)
    end

    it_behaves_like 'unauthenticated not allowed' do
      before do
        get checks_project_resource_path(@project, resource)
      end
    end

    it_behaves_like 'authenticated' do
      def expect_checks_response(project, resource)
        get checks_project_resource_path(project, resource)
        expect(response).to be_successful
        expect(is_json_response?).to be true
        expect(response.body).to eq resource_checks.to_json
      end

      it_behaves_like 'a hub admin' do
        it 'returns the checks for the resource' do
          expect_checks_response @project, resource
        end
      end

      context 'not a hub admin' do
        context 'is in the project\'s team' do
          before do
            create :team_membership, team: @project.team, user: current_user
          end

          it 'returns the checks for the resource' do
            expect_checks_response @project, resource
          end
        end

        context 'is in a different team' do
          let(:other_project) { @other_projects.first }
          let(:other_team) { other_project.team }

          let! :resource do
            create :code_repo, project: other_project, integration: integration
          end

          before do
            create :team_membership, team: other_team, user: current_user
          end

          it 'can\'t get the checks for the resource' do
            expect(ResourceChecksService).to receive(:new).never
            get checks_project_resource_path(@project, resource)
            expect(response).to redirect_to root_path
            expect(flash[:alert]).not_to be_empty
          end

          it 'can still bootstrap resources for this different project' do
            expect_checks_response other_project, resource
          end
        end
      end
    end
  end
end
