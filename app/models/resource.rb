class Resource < ApplicationRecord
  include HasResourceStatus
  include SluggedAttribute
  include AttrJson::Record

  attr_json_config default_container_attribute: :metadata

  audited associated_with: :project

  belongs_to :parent,
    class_name: 'Resource',
    inverse_of: :children,
    optional: true

  has_many :children,
    -> { order(:integration_id) },
    foreign_key: 'parent_id',
    class_name: 'Resource',
    inverse_of: :parent,
    dependent: nil

  belongs_to :project,
    -> { readonly },
    inverse_of: :resources

  belongs_to :integration,
    -> { readonly },
    inverse_of: :resources

  belongs_to :requested_by,
    -> { readonly },
    class_name: 'User',
    inverse_of: false

  slugged_attribute :name,
    presence: true,
    uniqueness: { scope: :integration_id },
    readonly: true

  validate :check_integration_is_allowed

  attr_readonly :project_id, :integration_id, :requested_by_id

  def classification
    "#{self.class.model_name.human} - #{integration.provider_id.camelize}"
  end

  def descriptor
    "#{name} (#{classification})"
  end

  private

  def check_integration_is_allowed
    return if project.blank? || integration.blank?

    integration_to_check = if parent.present?
                             # Assume one level of parentage only
                             parent.integration
                           else
                             integration
                           end

    allowed_integrations = TeamIntegrationsService.get project.team

    return if allowed_integrations.include?(integration_to_check)

    errors.add(
      :integration,
      'cannot use the integration specified as it\'s not allowed for the project'
    )
  end
end

Dir[Rails.root.join('app', 'models', 'resources', '*.rb').to_s].each do |file|
  require_dependency file
end
