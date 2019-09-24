require 'rails_helper'

RSpec.describe 'Admin - Tasks', type: :request do
  describe 'new - GET /admin/tasks/new' do
    let :make_request do
      get new_admin_task_path(type: 'CreateKubeCluster', cluster_creator: 'gke')
    end

    it_behaves_like 'unauthenticated not allowed' do
      before do
        make_request
      end
    end

    it_behaves_like 'authenticated' do
      it_behaves_like 'not a hub admin so not allowed' do
        before do
          make_request
        end
      end

      it_behaves_like 'a hub admin' do
        it 'loads the new admin task page' do
          make_request
          expect(response).to be_successful
          expect(response).to render_template(:new)
        end
      end
    end
  end
end
