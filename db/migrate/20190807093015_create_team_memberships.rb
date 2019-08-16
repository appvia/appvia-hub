class CreateTeamMemberships < ActiveRecord::Migration[5.2]
  def change
    create_table :team_memberships, id: :uuid do |t|
      t.references :team, type: :uuid, null: false, foreign_key: true
      t.references :user, type: :uuid, null: false, foreign_key: true

      t.string :role

      t.timestamps

      t.index %i[team_id user_id], unique: true
    end
  end
end
