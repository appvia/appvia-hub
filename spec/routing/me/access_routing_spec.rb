require 'rails_helper'

RSpec.describe Me::AccessController, type: :routing do
  describe 'routing' do
    it 'routes to #show' do
      expect(get: '/me/access').to route_to('me/access#show')
    end
  end
end
