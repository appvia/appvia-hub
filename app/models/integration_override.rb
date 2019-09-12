class IntegrationOverride < ApplicationRecord
  include EncryptedConfigHashAttribute

  audited associated_with: :project

  belongs_to :project,
    -> { readonly },
    inverse_of: :integration_overrides

  belongs_to :integration,
    -> { readonly },
    inverse_of: false

  validates :integration_id,
    uniqueness: { scope: :project_id }

  validate :check_integration_is_allowed

  attr_readonly :project_id, :integration_id

  def config_schema
    return nil if integration.blank?

    integration_schema = integration.config_schema

    overridable_properties = integration_schema.properties.select do |_k, v|
      v.data['overridable'] == true
    end

    JsonSchema.parse!(
      'properties' => overridable_properties.transform_values(&:data)
    )
  end

  def descriptor
    "For space: #{project.friendly_id} - integration: #{integration.name}"
  end

  private

  def check_integration_is_allowed
    return if project.blank? || integration.blank?

    allowed_integrations = TeamIntegrationsService.get project.team

    return if allowed_integrations.include?(integration)

    errors.add(
      :integration,
      'cannot use the integration specified as it\'s not allowed for the project'
    )
  end
end
