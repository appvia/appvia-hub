class CreateTeams < ActiveRecord::Migration[5.2]
  def change
    create_table :teams, id: :uuid do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description

      t.timestamps

      t.index :slug, unique: true
    end
  end
end
