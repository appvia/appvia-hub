require 'rails_helper'

RSpec.describe TeamMembershipsController, type: :routing do
  describe 'routing' do
    it 'routes to #update via PUT' do
      expect(put: '/teams/1/memberships/foo').to route_to('team_memberships#update', team_id: '1', id: 'foo')
    end

    it 'routes to #destroy' do
      expect(delete: '/teams/1/memberships/foo').to route_to('team_memberships#destroy', team_id: '1', id: 'foo')
    end
  end
end
