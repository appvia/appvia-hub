require 'rails_helper'

RSpec.describe JsonSchemaHelpers do
  describe '#ensure_data_types' do
    let :input_spec do
      JsonSchema.parse!(
        'properties' => {
          'a_string' => { 'type' => 'string' },
          'a_boolean' => { 'type' => 'boolean' },
          'an_integer' => { 'type' => 'integer' },
          'embedded_object' => {
            'type' => 'object',
            'properties' => {
              'a_string' => { 'type' => 'string' },
              'a_boolean' => { 'type' => 'boolean' },
              'an_integer' => { 'type' => 'integer' }
            }
          },
          'embedded_array_of_objects' => {
            'type' => 'array',
            'items' => {
              'type' => 'object',
              'properties' => {
                'a_string' => { 'type' => 'string' },
                'a_boolean' => { 'type' => 'boolean' },
                'an_integer' => { 'type' => 'integer' }
              }
            }
          }
        }
      )
    end

    let :input_data do
      {
        'a_string' => 'foo',
        'a_boolean' => 'true',
        'an_integer' => '42',
        'embedded_object' => {
          'a_string' => 'foo',
          'a_boolean' => 'true',
          'an_integer' => '42'
        },
        'embedded_array_of_objects' => [
          {
            'a_string' => 'foo',
            'a_boolean' => 'true',
            'an_integer' => '42'
          },
          {
            'a_string' => 'foo',
            'a_boolean' => 'true',
            'an_integer' => '42'
          }
        ]
      }
    end

    let :expected_output do
      {
        'a_string' => 'foo',
        'a_boolean' => true,
        'an_integer' => 42,
        'embedded_object' => {
          'a_string' => 'foo',
          'a_boolean' => true,
          'an_integer' => 42
        },
        'embedded_array_of_objects' => [
          {
            'a_string' => 'foo',
            'a_boolean' => true,
            'an_integer' => 42
          },
          {
            'a_string' => 'foo',
            'a_boolean' => true,
            'an_integer' => 42
          }
        ]
      }
    end
    it 'converts data types to the expected schema data types as expected' do
      expect(
        JsonSchemaHelpers.ensure_data_types(
          input_data,
          input_spec
        )
      ).to eq expected_output
    end
  end

  describe '#transform_additional_properties' do
    let :input do
      {
        'person' => {
          'additional_properties' => [
            { 'key' => 'first_name', 'value' => 'fred' },
            { 'key' => 'last_name', 'value' => 'flintstone' }
          ]
        }
      }
    end

    let :input_nested do
      {
        'person' => {
          'additional_properties' => [
            { 'key' => 'first_name', 'value' => 'fred' },
            { 'key' => 'last_name', 'value' => 'flintstone' }
          ],
          'address' => {
            'additional_properties' => [
              { 'key' => 'house_number', 'value' => '1A' },
              { 'key' => 'post_code', 'value' => 'SE1 2AB' }
            ]
          }
        }
      }
    end

    let :expected do
      {
        'person' => {
          'first_name' => 'fred',
          'last_name' => 'flintstone'
        }
      }
    end

    let :expected_nested do
      {
        'person' => {
          'first_name' => 'fred',
          'last_name' => 'flintstone',
          'address' => {
            'house_number' => '1A',
            'post_code' => 'SE1 2AB'
          }
        }
      }
    end

    it 'transforms the additional properties directly onto the parent hash' do
      JsonSchemaHelpers.transform_additional_properties input
      expect(input).to eq expected
    end

    it 'does not transform one with an empty key' do
      input['person']['additional_properties'].first['key'] = ''
      expected['person'].delete 'first_name'
      JsonSchemaHelpers.transform_additional_properties input
      expect(input).to eq expected
    end

    it 'does transform one with an empty value' do
      input['person']['additional_properties'].second['value'] = ''
      expected['person']['last_name'] = nil
      JsonSchemaHelpers.transform_additional_properties input
      expect(input).to eq expected
    end

    it 'will transform recursively' do
      JsonSchemaHelpers.transform_additional_properties input_nested
      expect(input_nested).to eq expected_nested
    end
  end
end
