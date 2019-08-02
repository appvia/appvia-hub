module Admin
  class Task < ApplicationRecord
    include AttrJson::Record

    attr_json_config default_container_attribute: :data

    audited except: %i[data encrypted_data]

    belongs_to :created_by,
      -> { readonly },
      class_name: 'User',
      inverse_of: false

    enum status: {
      pending: 'pending',
      running: 'running',
      completed: 'completed',
      failed: 'failed'
    }

    validates :status, presence: true

    crypt_keeper :encrypted_data,
      encryptor: :active_support,
      key: Rails.application.secrets.secret_key_base,
      salt: Rails.application.secrets.secret_salt

    attr_readonly :created_by_id

    default_value_for :status, :pending
    default_value_for :encrypted_data, -> { {} }

    def encrypted_data=(hash)
      super hash.try(:to_json)
    end

    def encrypted_data
      value = super
      value.present? ? JSON.parse(value) : {}
    end

    def deleteable?
      !running? && !completed?
    end
  end
end

Dir[Rails.root.join('app', 'models', 'admin', 'tasks', '*.rb').to_s].each do |file|
  require_dependency file
end
