require 'rails_helper'

RSpec.describe Admin::IntegrationsController, type: :routing do
  describe 'routing' do
    it 'routes to #index' do
      expect(get: '/admin/integrations').to route_to('admin/integrations#index')
    end

    it 'routes to #new' do
      expect(get: '/admin/integrations/new').to route_to('admin/integrations#new')
    end

    it 'routes to #edit' do
      expect(get: '/admin/integrations/1/edit').to route_to('admin/integrations#edit', id: '1')
    end

    it 'routes to #create' do
      expect(post: '/admin/integrations').to route_to('admin/integrations#create')
    end

    it 'routes to #update via PUT' do
      expect(put: '/admin/integrations/1').to route_to('admin/integrations#update', id: '1')
    end

    it 'routes to #update via PATCH' do
      expect(patch: '/admin/integrations/1').to route_to('admin/integrations#update', id: '1')
    end
  end
end
