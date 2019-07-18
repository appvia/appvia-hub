class AddParentIdToIntegrations < ActiveRecord::Migration[5.2]
  def change
    add_column :integrations, :parent_ids, :uuid, array: true, null: false, default: [], index: true
  end
end
