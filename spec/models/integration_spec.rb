require 'rails_helper'

RSpec.describe Integration, type: :model do
  subject { create_mocked_integration }

  describe '#name' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name) }
  end

  describe '#provider_id' do
    it { is_expected.to validate_presence_of(:provider_id) }
    it { is_expected.to have_readonly_attribute(:provider_id) }
  end

  describe '#config' do
    it { is_expected.to validate_presence_of(:config) }

    context 'encryption, serialisation and persistence' do
      let :initial_config do
        { 'foo' => 'one', 'bar' => 'two' }
      end

      subject do
        create_mocked_integration config: initial_config
      end

      it 'persists and loads up the config from the db as expected' do
        subject.save!
        cp = Integration.find subject.id
        expect(cp.config).to be_a Hash
        expect(cp.config).to eq initial_config
      end

      it 'has encrypted the value in the database' do
        subject.save!
        cp = Integration.find subject.id
        expect(cp[:config]).to be_a String
        expect(cp[:config]).not_to be_blank
        expect(cp.config_before_type_cast).to be_a String
        expect(cp.config_before_type_cast).not_to be_blank
        expect(cp[:config]).not_to eq cp.config_before_type_cast
      end

      it 'updates as expected only if you assign the whole `config` again' do
        subject.save!
        cp = Integration.find subject.id
        cp.config = cp.config.merge('foo' => 'updated')
        expect(cp).to be_changed
        cp.save!
        expect(cp.reload.config['foo']).to eq 'updated'
      end

      it 'doesn\'t update if you update values in place' do
        # This is just down to how ActiveRecord works :(
        subject.save!
        cp = Integration.find subject.id
        cp.config['foo'] = 'updated'
        expect(cp).to be_changed # Says it's changed ...
        cp.save!
        expect(cp.reload.config).to eq initial_config # ... but hasn't actually updated it!
      end

      # TODO: when https://github.com/collectiveidea/audited/pull/485 is released
      # it 'redacts the config data from audits' do
      #   subject.save!
      #   audit = subject.audits.first
      #   expect(audit.action).to eq 'create'
      #   expect(audit.audited_changes['config']).to eq '[REDACTED]'
      # end
    end

    context '#process_config' do
      let(:provider_id) { Integration.provider_ids.keys.first }

      let :schema do
        JsonSchema.parse!(
          'properties' => {
            'foo' => { 'type' => 'boolean' }
          }
        )
      end

      let :initial_config do
        { 'foo' => '1' }
      end

      subject do
        create_mocked_integration(
          provider_id: provider_id,
          config: initial_config,
          schema: schema
        )
      end

      it 'ensures that boolean fields are stored in the correct format' do
        expect(subject.config['foo']).to be true
      end
    end

    context 'JSON Schema validation' do
      let(:provider_id) { Integration.provider_ids.keys.first }

      let :schema do
        JsonSchema.parse!(
          'properties' => {
            'foo' => { 'type' => 'string' },
            'bar' => { 'type' => 'string' }
          },
          'required' => %w[foo bar]
        )
      end

      let :valid_config do
        { 'foo' => 'one', 'bar' => 'two' }
      end

      subject do
        build :integration, provider_id: provider_id
      end

      before do
        # NOTE: usually in specs you MUST use the `mock_provider_config_schema`
        # helper to mock out config schemas. However, in this special case, we
        # need to test the actual validation flow without it being mocked out.
        # Hence the line below instead:
        allow(PROVIDERS_REGISTRY).to receive(:config_schemas)
          .and_return(provider_id => schema)
      end

      context 'for a valid config hash' do
        it 'is a valid instance' do
          subject.config = valid_config
          expect(subject).to be_valid
        end
      end

      context 'for an invalid config hash' do
        it 'registers an error on the field' do
          subject.config = { 'foo' => 1 }
          expect(subject).not_to be_valid
          expect(subject.errors).to_not be_empty
          expect(subject.errors[:config]).to be_present
        end
      end

      context 'updating an existing config hash' do
        before do
          subject.config = valid_config
          subject.save!
        end

        context 'still with a valid config hash' do
          it 'updates as expected' do
            cp = Integration.find subject.id
            cp.config = cp.config.merge('foo' => 'updated')
            expect(cp).to be_valid
          end
        end

        context 'now with an invalid config hash' do
          it 'registers an error on the field' do
            cp = Integration.find subject.id
            cp.config = cp.config.merge('foo' => 1)
            expect(cp).not_to be_valid
            expect(cp.errors).to_not be_empty
            expect(cp.errors[:config]).to be_present
          end
        end
      end
    end
  end

  context 'when parent(s) are required' do
    let(:parent_provider_id) { Integration.provider_ids.keys.first }
    let(:provider_id) { Integration.provider_ids.keys.second }
    let(:config) { { 'foo' => 'bar' } }

    let :resource_type do
      {
        top_level: false,
        depends_on: [parent_provider_id]
      }
    end

    let :parent_integration do
      create_mocked_integration provider_id: parent_provider_id
    end

    let :integration do
      build :integration,
        provider_id: provider_id,
        config: config,
        parent_ids: parent_ids
    end

    before do
      mock_provider_config_schema provider_id

      allow(ResourceTypesService).to receive(:for_integration)
        .with(anything)
        .and_return(top_level: true)

      allow(ResourceTypesService).to receive(:for_integration)
        .with(integration)
        .and_return(resource_type)
    end

    context 'when a valid parent is set' do
      let(:parent_ids) { [parent_integration.id] }

      before do
        integration.save!
      end

      it 'loads parents' do
        expect(integration.parents.entries).to contain_exactly parent_integration
      end

      it 'loads children' do
        expect(parent_integration.children.entries).to contain_exactly integration
      end
    end

    context 'when no parents have been set' do
      let(:parent_ids) { [] }

      it 'is not valid' do
        expect(integration).not_to be_valid
        expect(integration.errors).to_not be_empty
        expect(integration.errors[:parent_ids]).to be_present
      end
    end

    context 'when an invalid ID is set in parent_ids' do
      let(:parent_ids) { ['huh?'] }

      it 'is not valid' do
        expect(integration).not_to be_valid
        expect(integration.errors).to_not be_empty
        expect(integration.errors[:parent_ids]).to contain_exactly(
          'an unknown Integration ID has been found in the parent IDs'
        )
      end
    end

    context 'when a parent is set that isn\'t supposed to be' do
      let(:other_provider_id) { Integration.provider_ids.keys.third }

      let! :other_integration do
        create_mocked_integration provider_id: other_provider_id
      end

      before do
        mock_provider_config_schema other_provider_id
      end

      let(:parent_ids) { [other_integration.id] }

      it 'is not valid' do
        expect(integration).not_to be_valid
        expect(integration.errors).to_not be_empty
        expect(integration.errors[:parent_ids]).to contain_exactly(
          'an invalid parent has been detected'
        )
      end
    end

    context 'when trying to link an integration to a parent that already has a child integration of the same type as the new one' do
      let :existing_integration do
        build :integration,
          provider_id: provider_id,
          config: config,
          parent_ids: [parent_integration.id]
      end

      before do
        allow(ResourceTypesService).to receive(:for_integration)
          .with(existing_integration)
          .and_return(resource_type)

        existing_integration.save!
      end

      let(:parent_ids) { [parent_integration.id] }

      it 'is not valid' do
        expect(integration).not_to be_valid
        expect(integration.errors).to_not be_empty
        expect(integration.errors[:parent_ids]).to contain_exactly(
          'cannot link this to a parent as it already has a child integration of the same type'
        )
      end
    end
  end
end
