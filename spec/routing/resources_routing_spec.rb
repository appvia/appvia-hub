require 'rails_helper'

RSpec.describe ResourcesController, type: :routing do
  describe 'routing' do
    it 'routes to #new' do
      expect(get: '/spaces/foo/resources/new').to route_to('resources#new', project_id: 'foo')
    end

    it 'routes to #create' do
      expect(post: '/spaces/foo/resources').to route_to('resources#create', project_id: 'foo')
    end

    it 'routes to #destroy' do
      expect(delete: '/spaces/foo/resources/1').to route_to('resources#destroy', project_id: 'foo', id: '1')
    end

    it 'routes to #prepare_bootstrap' do
      expect(get: '/spaces/foo/resources/bootstrap').to route_to('resources#prepare_bootstrap', project_id: 'foo')
    end

    it 'routes to #bootstrap' do
      expect(post: '/spaces/foo/resources/bootstrap').to route_to('resources#bootstrap', project_id: 'foo')
    end

    it 'routes to #checks' do
      expect(get: '/spaces/foo/resources/1/checks').to route_to('resources#checks', project_id: 'foo', id: '1')
    end
  end
end
