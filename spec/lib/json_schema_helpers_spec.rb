require 'rails_helper'

RSpec.describe JsonSchemaHelpers do
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
