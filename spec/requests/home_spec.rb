require 'rails_helper'

RSpec.describe 'Home', type: :request do
  describe 'GET /' do
    it_behaves_like 'unauthenticated not allowed' do
      before do
        get root_path
      end
    end

    it_behaves_like 'authenticated' do
      before do
        # Create some data to show up in the home activity feed
        team = create :team
        create :team_membership, :admin, team: team, user: current_user
        create :project, team: team

        create_list :user, 2

        other_projects = create_list :project, 2
        other_projects.first.destroy!
      end

      it 'loads the homepage' do
        get root_path
        expect(response).to be_successful
        expect(response).to render_template(:show)
        expect(assigns(:activity)).not_to be_empty
      end
    end
  end
end
