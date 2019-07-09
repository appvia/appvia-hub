class AddAccessTokenToIdentities < ActiveRecord::Migration[5.2]
  def change
    add_column :identities, :access_token, :text
  end
end
