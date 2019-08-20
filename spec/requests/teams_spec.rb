require 'rails_helper'

RSpec.describe 'Teams', type: :request do
  include_context 'time helpers'

  before do
    # Create some other teams to ensure we have a broader pool of data
    @other_teams = create_list :team, 2
  end

  describe 'index - GET /teams' do
    it_behaves_like 'unauthenticated not allowed' do
      before do
        get teams_path
      end
    end

    it_behaves_like 'authenticated' do
      before do
        @teams = (
          create_list(:team, 3) +
          @other_teams
        ).sort_by(&:name)
      end

      it 'loads the teams index page' do
        get teams_path
        expect(response).to be_successful
        expect(response).to render_template(:index)
        expect(assigns(:teams)).to eq @teams
      end
    end
  end

  describe 'show - GET /teams/:id' do
    before do
      @team = create :team
    end

    it_behaves_like 'unauthenticated not allowed' do
      before do
        get team_path(@team)
      end
    end

    it_behaves_like 'authenticated' do
      it_behaves_like 'not a hub admin so not allowed' do
        before do
          get team_path(@team)
        end
      end

      def expect_team_show_page(team)
        get team_path(team)
        expect(response).to be_successful
        expect(response).to render_template(:show)
        expect(assigns(:team)).to eq team
        expect(assigns(:activity)).not_to be_empty
      end

      it_behaves_like 'a hub admin' do
        it 'loads the team page' do
          expect_team_show_page @team
        end
      end

      context 'not a hub admin but is team member of the team' do
        before do
          create :team_membership, team: @team, user: current_user
        end

        it 'loads the team page' do
          expect_team_show_page @team
        end

        it 'can\'t load the team page for a different team' do
          get team_path(@other_teams.first)
          expect(response).to redirect_to root_path
          expect(flash[:alert]).not_to be_empty
        end
      end
    end
  end

  describe 'new - GET /teams/new' do
    it_behaves_like 'unauthenticated not allowed' do
      before do
        get new_team_path
      end
    end

    it_behaves_like 'authenticated' do
      it 'loads the new team page' do
        get new_team_path
        expect(response).to be_successful
        expect(response).to render_template(:new)
        expect(assigns(:team)).to be_a Team
        expect(assigns(:team)).to be_new_record
      end
    end
  end

  describe 'edit - GET /teams/edit' do
    before do
      @team = create :team
    end

    it_behaves_like 'unauthenticated not allowed' do
      before do
        get edit_team_path(@team)
      end
    end

    it_behaves_like 'authenticated' do
      it_behaves_like 'not a hub admin so not allowed' do
        before do
          get edit_team_path(@team)
        end
      end

      def expect_edit_team_page(team)
        get edit_team_path(team)
        expect(response).to be_successful
        expect(response).to render_template(:edit)
        expect(assigns(:team)).to eq team
      end

      def expect_access_denied(team)
        get edit_team_path(team)
        expect(response).to redirect_to root_path
        expect(flash[:alert]).not_to be_empty
      end

      it_behaves_like 'a hub admin' do
        it 'loads the edit team page' do
          expect_edit_team_page @team
        end
      end

      context 'not a hub admin but is team member of the team' do
        before do
          create :team_membership, team: @team, user: current_user
        end

        it 'can\'t load the edit team page for the team' do
          expect_access_denied @team
        end

        it 'can\'t load the edit team page for a different team' do
          expect_access_denied @other_teams.first
        end
      end

      context 'not a hub admin but is team admin of the team' do
        before do
          create :team_membership, :admin, team: @team, user: current_user
        end

        it 'loads the edit team page' do
          expect_edit_team_page @team
        end

        it 'can\'t load the edit team page for a different team' do
          expect_access_denied @other_teams.first
        end
      end
    end
  end

  describe 'create - POST /teams' do
    let :params do
      {
        name: 'Foo',
        slug: 'foo-1',
        description: 'fooooooo'
      }
    end

    it_behaves_like 'unauthenticated not allowed' do
      before do
        post teams_path, params: { team: params }
      end
    end

    it_behaves_like 'authenticated' do
      context 'with valid params' do
        it 'creates a new Team with the given params and redirects to the team page' do
          expect do
            post teams_path, params: { team: params }
            team = assigns(:team)
            expect(response).to redirect_to(team)
            expect(team).to be_persisted
            expect(team.name).to eq params[:name]
            expect(team.slug).to eq params[:slug]
            expect(team.description).to eq params[:description]
            expect(team.created_at.to_i).to eq now.to_i
          end.to change { Team.count }.by(1)
        end

        it 'logs an Audit' do
          post teams_path, params: { team: params }
          team = assigns(:team)
          audit = team.audits.order(:created_at).last
          expect(audit.action).to eq 'create'
          expect(audit.user_email).to eq auth_email
          expect(audit.created_at.to_i).to eq now.to_i
        end
      end

      context 'with invalid params' do
        it 'loads the new page with errors' do
          expect do
            post teams_path, params: { team: { name: nil, slug: '1 2 3' } }
          end.not_to change(Team, :count)

          expect(response).to be_successful
          expect(response).to render_template(:new)
          team = assigns(:team)
          expect(team).not_to be_persisted
          expect(team.errors).to_not be_empty
          expect(team.errors[:name]).to be_present
          expect(team.errors[:slug]).to be_present
        end
      end
    end
  end

  describe 'update - PUT /teams/:id' do
    before do
      @team = create :team
    end

    let :updated_params do
      {
        name: 'Updated Name',
        description: 'Updated description'
      }
    end

    it_behaves_like 'unauthenticated not allowed' do
      before do
        put team_path(@team), params: { team: updated_params }
      end
    end

    it_behaves_like 'authenticated' do
      def expect_team_update(team, params)
        move_time_to 1.minute.from_now

        expect do
          put team_path(team), params: { team: params }
        end.not_to change(Team, :count)

        updated_team = Team.find team.id

        expect(response).to redirect_to(updated_team)
        expect(assigns(:team)).to eq updated_team
        expect(updated_team.name).to eq params[:name]
        expect(updated_team.description).to eq params[:description]
        expect(updated_team.updated_at.to_i).to eq now.to_i

        audit = updated_team.audits.order(:created_at).last
        expect(audit.action).to eq 'update'
        expect(audit.user_email).to eq auth_email
        expect(audit.created_at.to_i).to eq now.to_i
      end

      def expect_access_denied(team, params)
        original_name = team.name
        put team_path(team), params: { team: params }
        expect(Team.find(team.id).name).to eq original_name
        expect(response).to redirect_to root_path
        expect(flash[:alert]).not_to be_empty
      end

      it_behaves_like 'a hub admin' do
        context 'with valid params' do
          it 'updates the team with the given params and logs an audit and redirects to the team page' do
            expect_team_update @team, updated_params
          end
        end

        context 'with invalid params' do
          it 'loads the edit page with errors' do
            original_name = @team.name
            put team_path(@team), params: { team: { name: nil } }
            expect(response).to be_successful
            expect(response).to render_template(:edit)
            team = assigns(:team)
            expect(team.errors).to_not be_empty
            expect(team.errors[:name]).to be_present
            expect(Team.find(team.id).name).to eq original_name
          end
        end

        it 'silently ignores changes to the slug' do
          put team_path(@team), params: { team: { slug: 'updated-slug' } }
          expect(Team.exists?(slug: @team.slug)).to be true
          expect(Team.exists?(slug: 'updated-slug')).to be false
        end
      end

      context 'not a hub admin but is team member of the team' do
        before do
          create :team_membership, team: @team, user: current_user
        end

        it 'can\'t update the team' do
          expect_access_denied @team, updated_params
        end

        it 'can\'t update a different team' do
          expect_access_denied @other_teams.first, updated_params
        end
      end

      context 'not a hub admin but is team admin of the team' do
        before do
          create :team_membership, :admin, team: @team, user: current_user
        end

        it 'updates the team with the given params and logs an audit and redirects to the team page' do
          expect_team_update @team, updated_params
        end

        it 'can\'t update a different team' do
          expect_access_denied @other_teams.first, updated_params
        end
      end
    end
  end

  describe 'destroy - DELETE /teams/:id' do
    before do
      @team = create :team
    end

    it_behaves_like 'unauthenticated not allowed' do
      before do
        delete team_path(@team)
      end
    end

    it_behaves_like 'authenticated' do
      it_behaves_like 'not a hub admin so not allowed' do
        before do
          delete team_path(@team)
        end
      end

      def expect_team_destroy(team)
        move_time_to 1.minute.from_now

        expect do
          delete team_path(team)
        end.to change { Team.count }.by(-1)

        expect(Team.exists?(team.id)).to be false
        expect(response).to redirect_to(teams_url)

        audit = Audit
          .auditable_finder(team.id, Team.name)
          .order(:created_at)
          .last
        expect(audit).not_to be nil
        expect(audit.action).to eq 'destroy'
        expect(audit.user_email).to eq auth_email
        expect(audit.created_at.to_i).to eq now.to_i
      end

      def expect_access_denied(team)
        expect do
          delete team_path(team)
        end.not_to change(Team, :count)
        expect(response).to redirect_to root_path
        expect(flash[:alert]).not_to be_empty
        expect(Team.exists?(team.id)).to be true
      end

      it_behaves_like 'a hub admin' do
        it 'deletes the existing team and logs an audit and redirects to the teams index page' do
          expect_team_destroy @team
        end
      end

      context 'not a hub admin but is team member of the team' do
        before do
          create :team_membership, team: @team, user: current_user
        end

        it 'can\'t delete the team' do
          expect_access_denied @team
        end

        it 'can\'t delete a different team' do
          expect_access_denied @other_teams.first
        end
      end

      context 'not a hub admin but is team admin of the team' do
        before do
          create :team_membership, :admin, team: @team, user: current_user
        end

        it 'deletes the existing team and logs an audit and redirects to the teams index page' do
          expect_team_destroy @team
        end

        it 'can\'t delete a different team' do
          expect_access_denied @other_teams.first
        end
      end
    end
  end
end
