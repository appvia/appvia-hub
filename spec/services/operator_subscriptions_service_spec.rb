require 'rails_helper'

RSpec.describe OperatorSubscriptionsService, type: :service do
  let :agent do
    instance_double(OperatorAgent)
  end

  let :installplan_resource do
    K8s::Resource.new(load_json_fixture('subscriptions/installplan.json'))
  end

  let :channel_resource do
    K8s::Resource.new(load_json_fixture('subscriptions/channel.json'))
  end

  let :subscriptions_resource do
    [K8s::Resource.new(load_json_fixture('subscriptions/subscriptions.json'))]
  end

  let :subscription_resource do
    K8s::Resource.new(load_json_fixture('subscriptions/subscription.json'))
  end

  let :package_resource do
    K8s::Resource.new(load_json_fixture('subscriptions/package.json'))
  end

  let :catalog_resource do
    K8s::Resource.new(load_json_fixture('subscriptions/catalog.json'))
  end

  let(:package) { 'prometheus' }

  before do
    allow(agent).to receive(:get_catalog).and_return(catalog_resource)
    allow(agent).to receive(:get_installplan).and_return(installplan_resource)
    allow(agent).to receive(:get_package_by_channel).and_return(channel_resource)
    allow(agent).to receive(:get_package).and_return(package_resource)
    allow(agent).to receive(:get_subscription).and_return(subscription_resource)
    allow(agent).to receive(:list_subscriptions).and_return(subscriptions_resource)
    allow(agent).to receive(:parse_version).and_return('0.33.0')
    @service = OperatorSubscriptionsService.new agent
  end

  it 'should return a single subscription' do
    expect(@service.list).to be_an_instance_of Array
    expect(@service.list.count).to eq 1
  end

  describe '#list' do
    it 'should return a list of subscriptions' do
      list = @service.list
      expect(list).to be_an_instance_of Array
      expect(list.count).to eq 1
    end
  end

  describe '#get' do
    it 'should return the subscription' do
      s = @service.get('operators', 'prometheus')
      expect(s).to be_an_instance_of Hash
      expect(s[:catalog]).to be_an_instance_of Hash
      expect(s[:channel]).to be_an_instance_of K8s::Resource
      expect(s[:info]).to be_an_instance_of Hash
      expect(s[:package]).to be_an_instance_of K8s::Resource
      expect(s[:subscription]).to be_an_instance_of Hash
      expect(s[:info][:channel_name]).to eq 'beta'
      expect(s[:info][:crds].size).to eq 5
      expect(s[:info][:changelog].size).to eq 0
    end
  end
end
