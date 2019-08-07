class AddUserSearchIndex < ActiveRecord::Migration[5.2]
  def change
    add_index :users,
      'name gin_trgm_ops',
      name: 'users_search_name_idx',
      using: :gin,
      order: { name: :gin_trgm_ops }

    add_index :users,
      'email gin_trgm_ops',
      name: 'users_search_email_idx',
      using: :gin,
      order: { name: :gin_trgm_ops }
  end
end
