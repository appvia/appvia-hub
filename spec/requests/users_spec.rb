require 'rails_helper'

RSpec.describe 'Users', type: :request do
  describe 'index - GET /users' do
    it_behaves_like 'unauthenticated not allowed' do
      before do
        get users_path
      end
    end

    it_behaves_like 'authenticated' do
      before do
        create_list :user, 2
      end

      let :total_users do
        3 # Taking into account the current_user
      end

      it 'loads the users index page' do
        get users_path
        expect(response).to be_successful
        expect(response).to render_template(:index)
        expect(assigns(:users).size).to eq total_users
      end
    end
  end

  describe 'search - GET /user/search' do
    let(:query) { 'bob' }

    it_behaves_like 'unauthenticated not allowed' do
      before do
        get search_users_path, params: { q: query }
      end
    end

    it_behaves_like 'authenticated' do
      let!(:bob) { create :user, email: 'bob@example.com' }

      before do
        create_list :user, 2
      end

      it 'finds the user bob and only returns JSON' do
        get search_users_path, params: { q: query }
        expect(response).to be_successful
        expect(is_json_response?).to be true
        expect(json_response.size).to eq 1
        expect(pluck_from_json_response('id')).to contain_exactly bob.id
      end
    end
  end

  describe 'update_role - PUT/PATCH /users/:user_id/role' do
    before do
      @user = create :user, role: 'user'
    end

    it_behaves_like 'unauthenticated not allowed' do
      before do
        put user_role_path(@user), params: { role: 'admin' }
      end
    end

    it_behaves_like 'authenticated' do
      it_behaves_like 'not a hub admin so not allowed' do
        before do
          put user_role_path(@user), params: { role: 'admin' }
        end
      end

      it_behaves_like 'a hub admin' do
        it 'updates the specified user\'s role to admin' do
          expect(@user.admin?).to be false

          put user_role_path(@user), params: { role: 'admin' }

          expect(response).to redirect_to(users_path)

          expect(@user.reload.admin?).to be true
        end
      end
    end
  end
end
