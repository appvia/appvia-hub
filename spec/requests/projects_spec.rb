require 'rails_helper'

RSpec.describe 'Projects', type: :request do
  include_context 'time helpers'

  describe 'index - GET /spaces' do
    it_behaves_like 'unauthenticated not allowed' do
      before do
        get projects_path
      end
    end

    it_behaves_like 'authenticated' do
      before do
        @projects = create_list(:project, 3).sort_by(&:name)
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
        expect(ActivityService).to receive(:new)
          .and_return(activity_service)
        expect(activity_service).to receive(:for_project)
          .with(@project)
          .and_return([])
      end

      it 'loads the project page' do
        get project_path(@project)
        expect(response).to be_successful
        expect(response).to render_template(:show)
        expect(assigns(:project)).to eq @project
        expect(assigns(:grouped_resources)).to be_present
        expect(assigns(:activity)).to eq []
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
      context 'when no teams exist' do
        it 'redirects to the home page with a warning flash message' do
          get new_project_path
          expect(response).to redirect_to(root_path)
          expect(flash[:warning]).not_to be_empty
        end
      end

      context 'when teams do exist' do
        before do
          create_list :team, 3
        end

        it 'loads the new project page' do
          get new_project_path
          expect(response).to be_successful
          expect(response).to render_template(:new)
          expect(assigns(:project)).to be_a Project
          expect(assigns(:project)).to be_new_record
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
      it 'loads the edit project page' do
        get edit_project_path(@project)
        expect(response).to be_successful
        expect(response).to render_template(:edit)
        expect(assigns(:project)).to eq @project
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
      context 'with valid params' do
        it 'creates a new Project with the given params and redirects to the project page' do
          expect do
            post projects_path, params: { project: params }
            project = assigns(:project)
            expect(response).to redirect_to(project)
            expect(project).to be_persisted
            expect(project.team).to eq team
            expect(project.name).to eq params[:name]
            expect(project.slug).to eq params[:slug]
            expect(project.description).to eq params[:description]
            expect(project.created_at.to_i).to eq now.to_i
          end.to change { Project.count }.by(1)
        end

        it 'logs an Audit' do
          post projects_path, params: { project: params }
          project = assigns(:project)
          audit = project.audits.order(:created_at).last
          expect(audit.action).to eq 'create'
          expect(audit.associated).to eq team
          expect(audit.user_email).to eq auth_email
          expect(audit.created_at.to_i).to eq now.to_i
        end
      end

      context 'with invalid params' do
        it 'loads the new page with errors' do
          post projects_path, params: { project: { name: nil, slug: '1 2 3' } }
          expect(response).to be_successful
          expect(response).to render_template(:new)
          project = assigns(:project)
          expect(project).not_to be_persisted
          expect(project.errors).to_not be_empty
          expect(project.errors[:name]).to be_present
          expect(project.errors[:slug]).to be_present
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
      context 'with valid params' do
        it 'updates the existing Project with the given params and redirects to the project page' do
          expect do
            move_time_to 1.minute.from_now
            put project_path(@project), params: { project: updated_params }
            project = Project.find @project.id
            expect(response).to redirect_to(project)
            expect(assigns(:project)).to eq project
            expect(project.name).to eq updated_params[:name]
            expect(project.description).to eq updated_params[:description]
            expect(project.updated_at.to_i).to eq now.to_i
          end.to change { Project.count }.by(0)
        end

        it 'logs an Audit' do
          move_time_to 1.minute.from_now
          put project_path(@project), params: { project: updated_params }
          project = Project.find @project.id
          audit = project.audits.order(:created_at).last
          expect(audit.action).to eq 'update'
          expect(audit.user_email).to eq auth_email
          expect(audit.created_at.to_i).to eq now.to_i
        end
      end

      context 'with invalid params' do
        it 'loads the edit page with errors' do
          put project_path(@project), params: { project: { name: nil } }
          expect(response).to be_successful
          expect(response).to render_template(:edit)
          project = assigns(:project)
          expect(project.errors).to_not be_empty
          expect(project.errors[:name]).to be_present
        end
      end

      it 'silently ignores changes to the slug' do
        put project_path(@project), params: { project: { slug: 'updated-slug' } }
        expect(Project.exists?(slug: @project.slug)).to be true
        expect(Project.exists?(slug: 'updated-slug')).to be false
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
      it 'deletes the existing Project and redirects to the projects index page' do
        expect do
          delete project_path(@project)
          expect(Project.exists?(@project.id)).to be false
          expect(response).to redirect_to(projects_url)
        end.to change { Project.count }.by(-1)
      end

      it 'logs an Audit' do
        move_time_to 1.minute.from_now
        delete project_path(@project)
        audit = Audit
          .auditable_finder(@project.id, Project.name)
          .order(:created_at)
          .last
        expect(audit).not_to be nil
        expect(audit.action).to eq 'destroy'
        expect(audit.user_email).to eq auth_email
        expect(audit.created_at.to_i).to eq now.to_i
      end
    end
  end
end
