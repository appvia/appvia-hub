require 'rails_helper'

RSpec.describe 'Me - Access', type: :request do
  include_context 'time helpers'

  describe 'show - GET /me/access' do
    it_behaves_like 'unauthenticated not allowed' do
      before do
        get me_access_path
      end
    end

    it_behaves_like 'authenticated' do
      it 'loads the me access show page' do
        get me_access_path
        expect(response).to be_successful
        expect(response).to render_template(:show)
        expect(assigns(:groups)).not_to be nil
      end
    end
  end
end
