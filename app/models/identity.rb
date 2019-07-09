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
