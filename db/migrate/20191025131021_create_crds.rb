class CreateCrds < ActiveRecord::Migration[5.2]
  def change
    create_table :crds, id: :uuid do |t|
      t.jsonb :data, null: false, default: {}

      t.string :lock_version # For optimistic locking

      t.timestamps

      t.index :data, using: :gin
    end
  end
end
