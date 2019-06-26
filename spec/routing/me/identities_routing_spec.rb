require 'rails_helper'

RSpec.describe Me::IdentitiesController, type: :routing do
  describe 'routing' do
    it 'routes to #destroy' do
      expect(delete: '/me/identities/1').to route_to('me/identities#destroy', integration_id: '1')
    end
  end
end
