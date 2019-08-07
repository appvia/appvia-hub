class CreateTeamMemberships < ActiveRecord::Migration[5.2]
  def change
    create_join_table :teams, :users, table_name: :team_memberships, column_options: { type: :uuid } do |t|
      t.string :role

      t.timestamps

      t.index :user_id
      t.index :team_id
      t.index %i[team_id user_id], unique: true
    end
  end
end
