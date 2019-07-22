class DropResourceHierarchies < ActiveRecord::Migration[5.2]
  def change
    # rubocop:disable Rails/ReversibleMigration
    drop_table :resource_hierarchies
    # rubocop:enable Rails/ReversibleMigration
  end
end
