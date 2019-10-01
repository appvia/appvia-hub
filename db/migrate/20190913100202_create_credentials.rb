class CreateCredentials < ActiveRecord::Migration[5.2]
  def change
    create_table :credentials, id: :uuid do |t|
      t.belongs_to :integration, null: false, type: :uuid
      t.references :owner, polymorphic: true, type: :uuid, null: false, index: true
      t.string :kind, null: false, index: true
      t.string :name, null: false
      t.text :value, null: false
      t.text :description

      t.timestamps

      t.index %i[name integration_id], unique: true
    end
  end
end
