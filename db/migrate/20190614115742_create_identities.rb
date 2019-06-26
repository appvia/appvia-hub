class CreateIdentities < ActiveRecord::Migration[5.2]
  def change
    create_table :identities, id: :uuid do |t|
      t.belongs_to :user, null: false, type: :uuid
      t.belongs_to :integration, null: false, type: :uuid
      t.string :external_id, null: false
      t.string :external_username
      t.string :external_name
      t.string :external_email

      t.timestamps

      t.index %i[user_id integration_id], unique: true
      t.index %i[integration_id external_id], unique: true
    end
  end
end
