class CreateAdminTasks < ActiveRecord::Migration[5.2]
  def change
    create_table :admin_tasks, id: :uuid do |t|
      t.string :type, null: false # For Single Table Inheritance

      t.references :created_by, type: :uuid, null: false, foreign_key: { to_table: :users }, index: true
      t.string :status, null: false
      t.jsonb :data, null: false, default: {}
      t.text :encrypted_data, null: false

      t.datetime :started_at
      t.datetime :finished_at

      t.text :error

      t.string :lock_version # For optimistic locking

      t.timestamps

      t.index :type
      t.index :data, using: :gin
    end
  end
end
