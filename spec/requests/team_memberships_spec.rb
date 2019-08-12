require 'rails_helper'

RSpec.describe 'Team Memberships', type: :request do
  include_context 'time helpers'

  before do
    @team = create :team
    @user = create :user

    # Create some other teams to ensure we have a broader pool of data
    @other_teams = create_list :team, 2
  end

  describe 'update - PUT /teams/:team_id/memberships/:id' do
    it_behaves_like 'unauthenticated not allowed' do
      before do
        put team_membership_path(@team, @user)
      end
    end

    it_behaves_like 'authenticated' do
      it_behaves_like 'not a hub admin so not allowed' do
        before do
          put team_membership_path(@team, @user)
        end
      end

      def expect_team_membership_create_or_update(team, user, role: nil, expect_new: true)
        move_time_to 1.minute.from_now

        put team_membership_path(team, user, role: role)
        expect(response).to redirect_to(team_path(team, anchor: 'people'))
        team_membership = team.memberships.where(user_id: user.id).first
        expect(team_membership).not_to be nil
        expect(team_membership.role).to eq role
        expect(assigns(:team_membership)).to eq team_membership

        audit = team_membership.audits.order(:created_at).last
        action = expect_new ? 'create' : 'update'
        expect(audit.action).to eq action
        expect(audit.user_email).to eq auth_email
        expect(audit.created_at.to_i).to eq now.to_i
      end

      def expect_access_denied(team, user)
        put team_membership_path(team, user)
        expect(response).to redirect_to root_path
        expect(flash[:alert]).not_to be_empty
      end

      it_behaves_like 'a hub admin' do
        context 'when membership does not exist yet' do
          it 'creates the new team membership and logs an audit' do
            expect(@team.memberships.exists?(user_id: @user.id)).to be false
            expect_team_membership_create_or_update @team, @user, role: 'admin'
          end
        end

        context 'when membership exists and a role change is made' do
          before do
            create :team_membership, team: @team, user: @user
          end

          it 'updates the role of the existing team membership' do
            expect(@team.memberships.exists?(user_id: @user.id)).to be true
            expect_team_membership_create_or_update @team, @user, role: 'admin', expect_new: false
          end
        end
      end

      context 'not a hub admin but is team member of the team' do
        before do
          create :team_membership, team: @team, user: current_user
        end

        it 'can\'t create or update a team membership within the team' do
          expect_access_denied @team, @user
        end

        it 'can\'t create or update a team membership within a different team' do
          expect_access_denied @other_teams.first, @user
        end
      end

      context 'not a hub admin but is team admin of the team' do
        before do
          create :team_membership, :admin, team: @team, user: current_user
        end

        it 'can create and update a team membership for the team' do
          expect(@team.memberships.exists?(user_id: @user.id)).to be false
          expect_team_membership_create_or_update @team, @user, role: nil

          expect(@team.memberships.exists?(user_id: @user.id)).to be true
          expect_team_membership_create_or_update @team, @user, role: 'admin', expect_new: false
        end

        it 'can\'t create or update a team membership within a different team' do
          expect_access_denied @other_teams.first, @user
        end
      end
    end
  end

  describe 'destroy - DELETE /teams/:team_id/memberships/:id' do
    it_behaves_like 'unauthenticated not allowed' do
      before do
        delete team_membership_path(@team, @user)
      end
    end

    it_behaves_like 'authenticated' do
      it_behaves_like 'not a hub admin so not allowed' do
        before do
          delete team_membership_path(@team, @user)
        end
      end

      def expect_team_membership_destroy(team, user, expect_audit: true)
        move_time_to 1.minute.from_now

        delete team_membership_path(team, user)

        expect(response).to redirect_to(team_path(team, anchor: 'people'))
        expect(team.memberships.exists?(user_id: user.id)).to be false

        return unless expect_audit

        audit = team.associated_audits.order(:created_at).last
        expect(audit).not_to be nil
        expect(audit.action).to eq 'destroy'
        expect(audit.user_email).to eq auth_email
        expect(audit.created_at.to_i).to eq now.to_i
      end

      def expect_access_denied(team, user)
        expect do
          delete team_membership_path(team, user)
        end.not_to change(TeamMembership, :count)
        expect(response).to redirect_to root_path
        expect(flash[:alert]).not_to be_empty
      end

      it_behaves_like 'a hub admin' do
        context 'when membership does not exist yet' do
          it 'doesn\'t do anything' do
            expect(@team.memberships.exists?(user_id: @user.id)).to be false
            expect_team_membership_destroy @team, @user, expect_audit: false
          end
        end

        context 'when membership exists' do
          before do
            create :team_membership, team: @team, user: @user
          end

          it 'deletes the existing team membership' do
            expect(@team.memberships.exists?(user_id: @user.id)).to be true
            expect_team_membership_destroy @team, @user, expect_audit: true
          end
        end
      end

      context 'not a hub admin but is team member of the team' do
        before do
          create :team_membership, team: @team, user: current_user

          create :team_membership, team: @team, user: @user
        end

        it 'can\'t delete a team membership within the team' do
          expect_access_denied @team, @user
        end

        it 'can\'t delete a team membership within a different team' do
          expect_access_denied @other_teams.first, @user
        end
      end

      context 'not a hub admin but is team admin of the team' do
        before do
          create :team_membership, :admin, team: @team, user: current_user

          create :team_membership, team: @team, user: @user
        end

        it 'can delete a team membership for the team' do
          expect(@team.memberships.exists?(user_id: @user.id)).to be true
          expect_team_membership_destroy @team, @user, expect_audit: true
        end

        it 'can\'t create or update a team membership within a different team' do
          expect_access_denied @other_teams.first, @user
        end
      end
    end
  end
end
