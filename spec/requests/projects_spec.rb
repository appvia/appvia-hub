require 'rails_helper'

RSpec.describe 'Projects', type: :request do
  include_context 'time helpers'

  before do
    # Create some other projects to ensure we have a broader pool of data
    @other_projects = create_list :project, 2
    @other_teams = @other_projects.map(&:team)
  end

  describe 'index - GET /spaces' do
    it_behaves_like 'unauthenticated not allowed' do
      before do
        get projects_path
      end
    end

    it_behaves_like 'authenticated' do
      before do
        @projects = (
          create_list(:project, 3) +
          @other_projects
        ).sort_by(&:name)
      end

      it 'loads the projects index page' do
        get projects_path
        expect(response).to be_successful
        expect(response).to render_template(:index)
        expect(assigns(:projects)).to eq @projects
      end
    end
  end

  describe 'show - GET /spaces/:id' do
    before do
      @project = create :project
    end

    it_behaves_like 'unauthenticated not allowed' do
      before do
        get project_path(@project)
      end
    end

    it_behaves_like 'authenticated' do
      let(:activity_service) { instance_double('ActivityService') }

      before do
        allow(ActivityService).to receive(:new)
          .and_return(activity_service)
        allow(activity_service).to receive(:for_project)
          .with(@project)
          .and_return([])
      end

      it_behaves_like 'not a hub admin so not allowed' do
        before do
          get project_path(@project)
        end
      end

      def expect_project_show_page(project)
        get project_path(project)
        expect(response).to be_successful
        expect(response).to render_template(:show)
        expect(assigns(:project)).to eq project
        expect(assigns(:grouped_resources)).to be_present
        expect(assigns(:activity)).to eq []
      end

      it_behaves_like 'a hub admin' do
        it 'loads the project page' do
          expect_project_show_page @project
        end
      end

      context 'not a hub admin but is team member of the project\'s team' do
        before do
          create :team_membership, team: @project.team, user: current_user
        end

        it 'loads the project page' do
          expect_project_show_page @project
        end

        it 'can\'t load the project page for a different project' do
          get project_path(@other_projects.first)
          expect(response).to redirect_to root_path
          expect(flash[:alert]).not_to be_empty
        end
      end
    end
  end

  describe 'new - GET /spaces/new' do
    it_behaves_like 'unauthenticated not allowed' do
      before do
        get new_project_path
      end
    end

    it_behaves_like 'authenticated' do
      def expect_new_project_page(allowed_teams)
        get new_project_path
        expect(response).to be_successful
        expect(response).to render_template(:new)
        expect(assigns(:project)).to be_a Project
        expect(assigns(:project)).to be_new_record
        expect(assigns(:teams)).to match_array allowed_teams
      end

      it_behaves_like 'a hub admin' do
        it 'loads the new project page' do
          expect_new_project_page @other_teams
        end
      end

      context 'not a hub admin' do
        context 'is not in any teams' do
          it 'redirects to the home page with a warning flash message' do
            get new_project_path
            expect(response).to redirect_to(root_path)
            expect(flash[:warning]).not_to be_empty
          end
        end

        context 'is in a team' do
          let!(:team) { create :team }

          before do
            create :team_membership, team: team, user: current_user
          end

          it 'loads the new project page' do
            expect_new_project_page([team])
          end

          context 'but a different team is specified in the query param' do
            it 'can\'t load the new project page' do
              get new_project_path(team_id: @other_teams.first.id)
              expect(response).to redirect_to root_path
              expect(flash[:alert]).not_to be_empty
            end
          end
        end
      end
    end
  end

  describe 'edit - GET /spaces/edit' do
    before do
      @project = create :project
    end

    it_behaves_like 'unauthenticated not allowed' do
      before do
        get edit_project_path(@project)
      end
    end

    it_behaves_like 'authenticated' do
      def expect_edit_project_page(project, allowed_teams)
        get edit_project_path(project)
        expect(response).to be_successful
        expect(response).to render_template(:edit)
        expect(assigns(:project)).to eq project
        expect(assigns(:teams)).to match_array allowed_teams
      end

      def expect_access_denied(project)
        get edit_project_path(project)
        expect(response).to redirect_to root_path
        expect(flash[:alert]).not_to be_empty
      end

      it_behaves_like 'a hub admin' do
        it 'loads the edit project page' do
          expect_edit_project_page @project, [@project.team] + @other_teams
        end
      end

      context 'not a hub admin' do
        context 'is not in any teams' do
          it 'redirects to the home page with a warning flash message' do
            get edit_project_path(@project)
            expect(response).to redirect_to(root_path)
            expect(flash[:warning]).not_to be_empty
          end
        end

        context 'is in the project\'s team' do
          before do
            create :team_membership, team: @project.team, user: current_user
          end

          it 'loads the edit project page' do
            expect_edit_project_page(@project, [@project.team])
          end
        end

        context 'is in a different team' do
          let(:other_project) { @other_projects.first }
          let(:other_team) { other_project.team }

          before do
            create :team_membership, team: other_team, user: current_user
          end

          it 'can\'t load the edit project page for the project' do
            expect_access_denied @project
          end

          it 'can still load the edit page for a project in this different team' do
            expect_edit_project_page(other_project, [other_team])
          end
        end
      end
    end
  end

  describe 'create - POST /spaces' do
    let!(:team) { create :team }

    let :params do
      {
        team_id: team.id,
        name: 'Foo',
        slug: 'foo-1',
        description: 'fooooooo'
      }
    end

    it_behaves_like 'unauthenticated not allowed' do
      before do
        post projects_path, params: { project: params }
      end
    end

    it_behaves_like 'authenticated' do
      def expect_project_create(params)
        expect do
          post projects_path, params: { project: params }
        end.to change { Project.count }.by(1)

        project = assigns(:project)
        expect(response).to redirect_to(project)
        expect(project).to be_persisted
        expect(project.team_id).to eq params[:team_id]
        expect(project.name).to eq params[:name]
        expect(project.slug).to eq params[:slug]
        expect(project.description).to eq params[:description]
        expect(project.created_at.to_i).to eq now.to_i

        audit = project.audits.order(:created_at).last
        expect(audit.action).to eq 'create'
        expect(audit.associated_id).to eq params[:team_id]
        expect(audit.user_email).to eq auth_email
        expect(audit.created_at.to_i).to eq now.to_i
      end

      def expect_access_denied(params)
        expect do
          post projects_path, params: { project: params }
        end.not_to change(Project, :count)
        expect(response).to redirect_to root_path
        expect(flash[:alert]).not_to be_empty
      end

      it_behaves_like 'a hub admin' do
        context 'with valid params' do
          it 'creates a new project with the given params and logs and audit and redirects to the project page' do
            expect_project_create params
          end
        end

        context 'with invalid params' do
          it 'loads the new page with errors' do
            expect do
              post projects_path, params: { project: { name: nil, slug: '1 2 3' } }
            end.not_to change(Project, :count)

            expect(response).to be_successful
            expect(response).to render_template(:new)
            project = assigns(:project)
            expect(project).not_to be_persisted
            expect(project.errors).to_not be_empty
            expect(project.errors[:name]).to be_present
            expect(project.errors[:slug]).to be_present
            expect(assigns(:teams)).to match_array([team] + @other_teams)
          end
        end
      end

      context 'not a hub admin' do
        context 'is not in any teams' do
          it 'redirects to the home page with a warning flash message' do
            expect do
              post projects_path, params: { project: params }
            end.not_to change(Project, :count)
            expect(response).to redirect_to(root_path)
            expect(flash[:warning]).not_to be_empty
          end
        end

        context 'is in the team specified in the input params' do
          before do
            create :team_membership, team: team, user: current_user
          end

          it 'creates a new project with the given params and logs and audit and redirects to the project page' do
            expect_project_create params
          end
        end

        context 'is in a different team to the one specified in the input params' do
          let(:other_team) { @other_teams.first }

          before do
            create :team_membership, team: other_team, user: current_user
          end

          it 'can\'t create a project within the specified team' do
            expect_access_denied params
          end

          it 'can still create a project within this different team' do
            expect_project_create params.merge(team_id: other_team.id)
          end
        end
      end
    end
  end

  describe 'update - PUT /spaces/:id' do
    before do
      @project = create :project
    end

    let :updated_params do
      {
        name: 'Updated Name',
        description: 'Updated description'
      }
    end

    it_behaves_like 'unauthenticated not allowed' do
      before do
        put project_path(@project), params: { project: updated_params }
      end
    end

    it_behaves_like 'authenticated' do
      def expect_project_update(project, params)
        move_time_to 1.minute.from_now

        expect do
          put project_path(project), params: { project: params }
        end.not_to change(Project, :count)

        updated_project = Project.find project.id

        expect(response).to redirect_to(updated_project)
        expect(assigns(:project)).to eq updated_project
        expect(updated_project.name).to eq params[:name]
        expect(updated_project.description).to eq params[:description]
        expect(updated_project.updated_at.to_i).to eq now.to_i

        audit = updated_project.audits.order(:created_at).last
        expect(audit.action).to eq 'update'
        expect(audit.user_email).to eq auth_email
        expect(audit.created_at.to_i).to eq now.to_i
      end

      def expect_access_denied(project, params)
        original_name = project.name
        put project_path(project), params: { project: params }
        expect(Project.find(project.id).name).to eq original_name
        expect(response).to redirect_to root_path
        expect(flash[:alert]).not_to be_empty
      end

      it_behaves_like 'a hub admin' do
        context 'with valid params' do
          it 'updates the project with the given params and logs an audit and redirects to the project page' do
            expect_project_update @project, updated_params
          end
        end

        context 'with invalid params' do
          it 'loads the edit page with errors' do
            original_name = @project.name
            put project_path(@project), params: { project: { name: nil } }
            expect(response).to be_successful
            expect(response).to render_template(:edit)
            project = assigns(:project)
            expect(project.errors).to_not be_empty
            expect(project.errors[:name]).to be_present
            expect(assigns(:teams)).to match_array([@project.team] + @other_teams)
            expect(Project.find(project.id).name).to eq original_name
          end
        end

        it 'silently ignores changes to the slug' do
          put project_path(@project), params: { project: { slug: 'updated-slug' } }
          expect(Project.exists?(slug: @project.slug)).to be true
          expect(Project.exists?(slug: 'updated-slug')).to be false
        end
      end

      context 'not a hub admin' do
        context 'is not in any teams' do
          it 'redirects to the home page with a warning flash message' do
            put project_path(@project), params: { project: updated_params }
            expect(response).to redirect_to(root_path)
            expect(flash[:warning]).not_to be_empty
          end
        end

        context 'is in the project\'s team' do
          before do
            create :team_membership, team: @project.team, user: current_user
          end

          it 'updates the project with the given params and logs an audit and redirects to the project page' do
            expect_project_update @project, updated_params
          end
        end

        context 'is in a different team' do
          let(:other_project) { @other_projects.first }
          let(:other_team) { other_project.team }

          before do
            create :team_membership, team: other_team, user: current_user
          end

          it 'can\'t update the project' do
            expect_access_denied @project, updated_params
          end

          it 'can still update a project within this different team' do
            expect_project_update other_project, updated_params
          end
        end
      end
    end
  end

  describe 'destroy - DELETE /spaces/:id' do
    before do
      @project = create :project
    end

    it_behaves_like 'unauthenticated not allowed' do
      before do
        delete project_path(@project)
      end
    end

    it_behaves_like 'authenticated' do
      it_behaves_like 'not a hub admin so not allowed' do
        before do
          delete project_path(@project)
        end
      end

      def expect_project_destroy(project)
        move_time_to 1.minute.from_now

        expect do
          delete project_path(project)
        end.to change { Project.count }.by(-1)

        expect(Project.exists?(project.id)).to be false
        expect(response).to redirect_to(team_path(project.team.id))

        audit = Audit
          .auditable_finder(project.id, Project.name)
          .order(:created_at)
          .last
        expect(audit).not_to be nil
        expect(audit.action).to eq 'destroy'
        expect(audit.user_email).to eq auth_email
        expect(audit.created_at.to_i).to eq now.to_i
      end

      def expect_access_denied(project)
        expect do
          delete project_path(project)
        end.not_to change(Project, :count)
        expect(response).to redirect_to root_path
        expect(flash[:alert]).not_to be_empty
        expect(Project.exists?(project.id)).to be true
      end

      it_behaves_like 'a hub admin' do
        it 'deletes the existing project and logs an audit and redirects to the project\'s team page' do
          expect_project_destroy @project
        end
      end

      context 'not a hub admin' do
        context 'is not in any teams' do
          it 'can\'t delete the project' do
            expect_access_denied @project
          end
        end

        context 'is in the project\'s team' do
          before do
            create :team_membership, team: @project.team, user: current_user
          end

          it 'deletes the existing project and logs an audit and redirects to the project\'s team page' do
            expect_project_destroy @project
          end
        end

        context 'is in a different team' do
          let(:other_project) { @other_projects.first }
          let(:other_team) { other_project.team }

          before do
            create :team_membership, team: other_team, user: current_user
          end

          it 'can\'t delete the project' do
            expect_access_denied @project
          end

          it 'can still delete a project within this different team' do
            expect_project_destroy other_project
          end
        end
      end
    end
  end
end
