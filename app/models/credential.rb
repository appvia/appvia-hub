class Credential < ApplicationRecord
  include SluggedAttribute

  audited associated_with: :owner

  scope :by_integration, lambda { |id|
    where integration_id: id
  }
  scope :by_owner, lambda { |owner_type, owner_id|
    where owner_type: owner_type, owner_id: owner_id
  }

  belongs_to :integration,
    -> { readonly },
    inverse_of: :credentials

  belongs_to :owner,
    -> { readonly },
    polymorphic: true,
    inverse_of: false

  enum kind: {
    user: 'user',
    robot: 'robot'
  }

  validates :kind, presence: true

  slugged_attribute :name,
    presence: true,
    uniqueness: { scope: :integration_id },
    readonly: true

  crypt_keeper :value,
    encryptor: :active_support,
    key: Rails.application.secrets.secret_key_base,
    salt: Rails.application.secrets.secret_salt

  validates :value, presence: true

  validate :check_integration_is_allowed

  attr_readonly :integration_id

  def descriptor
    name
  end

  def full_name
    case integration.provider_id
    when 'quay'
      "#{integration.config['org']}+#{name}"
    else
      name
    end
  end

  private

  def check_integration_is_allowed
    return if integration.blank? || owner.blank?

    allowed_integrations = case owner_type
                           when 'Team'
                             TeamIntegrationsService.get owner
                           when 'Project'
                             TeamIntegrationsService.get owner.team
                           when 'User'
                             TeamIntegrationsService.for_user owner
                           else
                             raise 'Unknown owner_type'
                           end

    return if allowed_integrations.include?(integration)

    errors.add(
      :integration,
      'cannot use the integration specified as it\'s not allowed for the owner specified'
    )
  end
end
