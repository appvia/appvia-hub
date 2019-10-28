class CreateClusters < ActiveRecord::Migration[5.2]
  def change
    create_table :clusters, id: :uuid do |t|
      t.references :team, type: :uuid, null: false, foreign_key: true, index: true
      t.references :crd, type: :uuid, null: false, foreign_key: true
      t.references :created_by, type: :uuid, null: false, foreign_key: { to_table: :users }

      t.string :name, null: false

      t.string :status, null: false
      t.text :error

      t.string :lock_version # For optimistic locking

      t.timestamps

      t.index :name, unique: true
    end
  end
end
