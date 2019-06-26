require 'rails_helper'

RSpec.describe Me::IdentityFlowsController, type: :routing do
  describe 'routing' do
    describe 'GitHub identity flow routes' do
      it 'routes to #git_hub_start' do
        expect(get: '/me/identity_flows/1/git_hub/start').to route_to('me/identity_flows#git_hub_start', integration_id: '1')
      end

      it 'routes to #git_hub_callback' do
        expect(get: '/me/identity_flows/1/git_hub/callback').to route_to('me/identity_flows#git_hub_callback', integration_id: '1')
      end
    end
  end
end
