class AddTeamIdToProject < ActiveRecord::Migration[5.2]
  def change
    add_column :projects, :team_id, :uuid
    add_index :projects, :team_id
  end
end
