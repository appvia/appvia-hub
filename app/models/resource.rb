class Resource < ApplicationRecord
  include SluggedAttribute
  include AttrJson::Record

  attr_json_config default_container_attribute: :metadata

  audited associated_with: :project

  has_closure_tree order: 'integration_id', dependent: nil

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

  enum status: {
    pending: 'pending',
    active: 'active',
    deleting: 'deleting',
    failed: 'failed'
  }

  validates :status, presence: true

  slugged_attribute :name,
    presence: true,
    uniqueness: { scope: :integration_id },
    readonly: true

  attr_readonly :project_id, :integration_id, :requested_by_id

  default_value_for :status, :pending

  def classification
    "#{self.class.model_name.human} - #{integration.provider_id.camelize}"
  end

  def descriptor
    "#{name} (#{classification})"
  end
end

Dir[Rails.root.join('app', 'models', 'resources', '*.rb').to_s].each do |file|
  require_dependency file
end
