module EncryptedConfigHashAttribute
  extend ActiveSupport::Concern

  # Important assumptions:
  # - the presence of a db field `config` of type `text`

  included do
    crypt_keeper :config,
      encryptor: :active_support,
      key: Rails.application.secrets.secret_key_base,
      salt: Rails.application.secrets.secret_salt

    default_value_for :config, -> { {} }
  end
end
