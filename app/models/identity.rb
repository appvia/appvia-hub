class Identity < ApplicationRecord
  audited associated_with: :user

  belongs_to :user
  validates :user_id, presence: true

  belongs_to :integration
  validates :integration_id,
    presence: true,
    uniqueness: { scope: :user_id }

  validates :external_id,
    presence: true,
    uniqueness: { scope: :integration_id }

  crypt_keeper :access_token,
    encryptor: :active_support,
    key: Rails.application.secrets.secret_key_base,
    salt: Rails.application.secrets.secret_salt

  validate :check_integration_is_allowed

  attr_readonly :user_id, :integration_id

  after_create_commit :trigger_created_worker
  after_destroy_commit :trigger_deleted_worker

  def descriptor
    "For integration: #{integration.name}"
  end

  def external_info
    {
      'ID' => external_id,
      'Username' => external_username,
      'Name' => external_name,
      'Email' => external_email
    }.compact
  end

  private

  def check_integration_is_allowed
    return if user.blank? || integration.blank?

    allowed_integrations = TeamIntegrationsService.for_user user

    return if allowed_integrations.include?(integration)

    errors.add(
      :integration,
      'cannot use the integration specified as it\'s not allowed for the user'
    )
  end

  def trigger_created_worker
    HandleIdentityCreatedWorker.perform_async id
  end

  def trigger_deleted_worker
    HandleIdentityDeletedWorker.perform_async(
      integration.id,
      external_info
    )
  end
end
