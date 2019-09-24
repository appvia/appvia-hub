class EnablePgTrgm < ActiveRecord::Migration[5.2]
  def change
    enable_extension 'pg_trgm'
  end
end
