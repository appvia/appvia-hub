class AddRequestedByToResources < ActiveRecord::Migration[5.2]
  def change
    add_column :resources, :requested_by_id, :uuid
  end
end
