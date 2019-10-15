require 'rails_helper'

RSpec.describe Admin::OperatorSubscriptionsController, type: :routing do
  describe 'routing' do
    it 'routes to #index' do
      expect(get: '/admin/operator_subscriptions/id').to route_to('admin/operator_subscriptions#index', integration_id: 'id')
    end

    it 'routes to #show' do
      expect(get: '/admin/operator_subscriptions/id/namespace/name').to route_to('admin/operator_subscriptions#show',
                                                                        integration_id: 'id',
                                                                        namespace: 'namespace',
                                                                        name: 'name')
    end

    it 'routes to #approve' do
      expect(get: '/admin/operator_subscriptions/id/namespace/name/approve').to route_to('admin/operator_subscriptions#approve',
                                                                        integration_id: 'id',
                                                                        namespace: 'namespace',
                                                                        name: 'name')
    end
  end
end
