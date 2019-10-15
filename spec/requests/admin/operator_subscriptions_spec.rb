require 'rails_helper'

RSpec.describe 'Admin - Integrations - Operator Subscriptions', type: :request do
  include_context 'time helpers'

  describe 'index - GET /admin/integrations/operator_subscriptions' do
    before do
      @integration = create_mocked_integration(
        provider_id: 'kubernetes',
        config: {
          api_url: 'http://127.0.0.1',
          ca_cert: nil,
          token: 'kube API token'
        }
      )
    end

    it_behaves_like 'unauthenticated not allowed' do
      before do
        get admin_operator_subscriptions_path @integration
      end
    end
  end
end
