require 'rails_helper'

RSpec.describe 'Service Catalog Instances' do
  include_examples 'resource integration specs' do
    let(:provider_id) { 'service_catalog' }

    let :integration_config do
      {
        api_url: 'url-to-kube-api',
        ca_cert: 'kube CA cert',
        token: 'kube API token'
      }
    end

    let :parent_integration do
      create_mocked_integration(
        provider_id: 'kubernetes',
        config: {
          api_url: 'url-to-kube-api',
          ca_cert: 'kube CA cert',
          token: 'kube API token'
        }
      )
    end

    let! :parent do
      create :kube_namespace, integration: parent_integration
    end

    let! :resource do
      create :service_catalog,
        name: 'service-catalog-instance',
        parent: parent,
        integration: integration,
        class_name: 'abcd-1234',
        class_external_name: 's3',
        class_display_name: 'S3',
        plan_name: 'efgh-5678',
        plan_external_name: 'production',
        plan_display_name: 'Production',
        create_parameters: {
          SomeParameter: 'value'
        }
    end

    let(:agent_class) { ServiceCatalogAgent }
    let :agent_initializer_params do
      {
        kube_api_url: 'url-to-kube-api',
        kube_ca_cert: 'kube CA cert',
        kube_token: 'kube API token'
      }
    end

    let :agent_create_response do
      {
        'kind' => 'ServiceInstance'
      }
    end

    let :agent_create_method_call_success do
      lambda do |agent, _resource|
        expect(agent).to receive(:create_resource)
          .with(
            namespace: parent.name,
            cluster_service_class_external_name: 's3',
            cluster_service_plan_external_name: 'production',
            name: 'service-catalog-instance',
            parameters: {
              'SomeParameter' => 'value'
            }
          )
          .and_return(agent_create_response)
      end
    end

    let :request_create_finished_success_expectations do
      lambda do |updated|
        expect(updated.metadata).to have_key 'service_instance'
        expect(updated.metadata['service_instance']).to include 'kind' => 'ServiceInstance'
      end
    end

    let :agent_create_method_call_error do
      lambda do |agent, _resource|
        expect(agent).to receive(:create_resource)
          .with(
            namespace: parent.name,
            cluster_service_class_external_name: 's3',
            cluster_service_plan_external_name: 'production',
            name: 'service-catalog-instance',
            parameters: {
              'SomeParameter' => 'value'
            }
          )
          .and_raise('Something broked')
      end
    end

    let :request_create_finished_error_expectations do
      lambda do |updated|
        expect(updated.metadata).not_to have_key 'service_instance'
      end
    end

    let :request_delete_before_setup_resource_state do
      lambda do |resource|
      end
    end

    let :agent_delete_method_call_success do
      lambda do |agent, _resource|
        expect(agent).to receive(:delete_resource)
          .with(namespace: parent.name, name: 'service-catalog-instance')
          .and_return(true)
      end
    end

    let :agent_delete_method_call_error do
      lambda do |agent, _resource|
        expect(agent).to receive(:delete_resource)
          .with(namespace: parent.name, name: 'service-catalog-instance')
          .and_raise('Something broked')
      end
    end
  end
end
