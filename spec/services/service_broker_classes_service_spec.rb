require 'rails_helper'

RSpec.describe ServiceBrokerClassesService, type: :service do
  let :agent do
    instance_double(ServiceBrokerAgent)
  end

  let :service_classes do
    s3_class_json = load_json_fixture 'service_broker/class_s3.json'
    s3_class_plans_json = load_json_fixture 'service_broker/class_s3_plans.json'
    sqs_class_json = load_json_fixture 'service_broker/class_sqs.json'
    sqs_class_plans_json = load_json_fixture 'service_broker/class_sqs_plans.json'

    s3_class = K8s::Resource.new s3_class_json
    s3_class.plans = s3_class_plans_json.map { |plan| K8s::Resource.new(plan) }
    sqs_class = K8s::Resource.new sqs_class_json
    sqs_class.plans = sqs_class_plans_json.map { |plan| K8s::Resource.new(plan) }

    [s3_class, sqs_class]
  end

  let(:s3_class_name) { '20e8cd7b-44bf-5590-bc43-48a68d8a8f14' }
  let(:s3_prod_plan_name) { '151c5162-66c5-530c-b1d6-707ef85b5d68' }

  before do
    allow(agent).to receive(:get_options).and_return(service_classes)
    @service = ServiceBrokerClassesService.new agent
  end

  it 'should have service classes available at the start' do
    expect(@service.service_classes).to be_an_instance_of Array
    expect(@service.service_classes.count).to eq 2
    expect(@service.service_classes).to eq service_classes
  end

  describe '#service_class' do
    it 'retrieves specific class' do
      service_class = @service.service_class s3_class_name
      expect(service_class).to respond_to :metadata
      expect(service_class.metadata.name).to eq s3_class_name
      expect(service_class.spec.externalMetadata.displayName).to eq 'Amazon S3'
    end

    it 'returns nil if no class is found' do
      expect(@service.service_class('invalid')).to eq nil
    end
  end

  describe '#service_plans' do
    it 'retrieves plans array for a specified class' do
      service_plans = @service.service_plans(s3_class_name)
      expect(service_plans).to be_an_instance_of Array
      expect(service_plans.count).to eq 2
    end

    it 'returns empty plans array if no class is found' do
      service_plans = @service.service_plans('invalid')
      expect(service_plans).to be_an_instance_of Array
      expect(service_plans.count).to eq 0
    end
  end

  describe '#service_plan' do
    it 'retrieves specific plan' do
      service_plan = @service.service_plan s3_class_name, s3_prod_plan_name
      expect(service_plan).to respond_to(:metadata)
      expect(service_plan.metadata.name).to eq s3_prod_plan_name
      expect(service_plan.spec.externalMetadata.displayName).to eq 'Production'
    end

    it 'returns nil if no plan is found' do
      expect(@service.service_plan(s3_class_name, 'invalid_plan')).to eq nil
      expect(@service.service_plan('invalid_class', 'invalid_plan')).to eq nil
    end
  end

  describe '#service_plan_schema' do
    it 'retrieves the schema for a specific plan' do
      plan_schema = @service.service_plan_schema s3_class_name, s3_prod_plan_name
      expect(plan_schema['$schema']).to eq 'http://json-schema.org/draft-06/schema#'
      expect(plan_schema['properties']).not_to be_empty
    end

    it 'returns nil if no schema can be found' do
      expect(@service.service_plan_schema(s3_class_name, 'invalid_plan')).to eq nil
      expect(@service.service_plan_schema('invalid_class', 'invalid_plan')).to eq nil
    end
  end

  describe '#generate_service_class_select_options' do
    it 'generates select options' do
      class_opts = @service.generate_service_class_select_options
      expect(class_opts).to be_an_instance_of Array
      expect(class_opts.count).to eq 2
      expect(class_opts.first).to eq ['Amazon S3', s3_class_name]
    end
  end

  describe '#generate_service_plans_select_options' do
    it 'generates select options' do
      plan_opts = @service.generate_service_plans_select_options s3_class_name
      expect(plan_opts).to be_an_instance_of Array
      expect(plan_opts.count).to eq 2
      expect(plan_opts.first).to eq ['Production - S3 Bucket pre-configured with production best practices', s3_prod_plan_name]
    end

    it 'generates empty list when class not found' do
      plan_opts = @service.generate_service_plans_select_options 'invalid'
      expect(plan_opts).to be_an_instance_of Array
      expect(plan_opts.count).to eq 0
    end
  end

  describe '#service_class_plan_names' do
    it 'returns hash of class and plan names' do
      names = @service.service_class_plan_names s3_class_name, s3_prod_plan_name
      expect(names[:class_name]).to eq s3_class_name
      expect(names[:class_external_name]).to eq 's3'
      expect(names[:class_display_name]).to eq 'Amazon S3'
      expect(names[:plan_name]).to eq s3_prod_plan_name
      expect(names[:plan_external_name]).to eq 'production'
      expect(names[:plan_display_name]).to eq 'Production'
    end

    it 'handles an invalid plan' do
      names = @service.service_class_plan_names s3_class_name, 'invalid_plan'
      expect(names[:class_name]).to eq s3_class_name
      expect(names[:class_external_name]).to eq 's3'
      expect(names[:class_display_name]).to eq 'Amazon S3'
      expect(names).not_to have_key :plan_name
      expect(names).not_to have_key :plan_external_name
      expect(names).not_to have_key :plan_display_name
    end

    it 'handles an invalid class' do
      expect(@service.service_class_plan_names('invalid_class', 'invalid_plan')).to be_empty
    end
  end
end
