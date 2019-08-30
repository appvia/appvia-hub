module MockedIntegrationHelper
  RSpec.shared_context 'mocked integration helper' do
    let(:empty_config_schema) { instance_double(JsonSchema::Schema, properties: {}) }

    def mock_provider_config_schema(provider_id, schema: nil)
      schema = empty_config_schema if schema.blank?

      updated_config_schemas = PROVIDERS_REGISTRY.config_schemas.merge(
        provider_id => schema
      )

      allow(PROVIDERS_REGISTRY).to receive(:config_schemas)
        .and_return(updated_config_schemas)

      allow(schema).to receive(:validate!)
        .and_return(true)
    end

    def create_mocked_integration(provider_id: Integration.provider_ids.keys.first, config: { 'foo' => 'bar' }, schema: nil, parent_ids: [])
      mock_provider_config_schema provider_id, schema: schema

      create :integration,
        provider_id: provider_id,
        config: config,
        parent_ids: parent_ids
    end
  end
end
