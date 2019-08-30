require 'rails_helper'

RSpec.describe Admin::TasksController, type: :routing do
  describe 'routing' do
    it 'routes to #new' do
      expect(get: '/admin/tasks/new').to route_to('admin/tasks#new')
    end

    it 'routes to #create' do
      expect(post: '/admin/tasks').to route_to('admin/tasks#create')
    end

    it 'routes to #destroy' do
      expect(delete: '/admin/tasks/1').to route_to('admin/tasks#destroy', id: '1')
    end
  end
end
