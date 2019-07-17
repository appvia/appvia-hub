require 'rails_helper'

RSpec.describe 'Admin - Create', type: :request do
  describe 'show - GET /admin/create' do
    it_behaves_like 'unauthenticated not allowed' do
      before do
        get admin_create_path
      end
    end

    it_behaves_like 'authenticated' do
      it_behaves_like 'not a hub admin so not allowed' do
        before do
          get admin_create_path
        end
      end

      it_behaves_like 'a hub admin' do
        it 'loads the admin create page' do
          get admin_create_path
          expect(response).to be_successful
          expect(response).to render_template(:show)
        end
      end
    end
  end
end
