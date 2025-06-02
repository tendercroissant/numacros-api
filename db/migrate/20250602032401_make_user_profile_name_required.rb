class MakeUserProfileNameRequired < ActiveRecord::Migration[8.0]
  def up
    # Update any existing records that might have null names
    execute "UPDATE user_profiles SET name = 'Unknown User' WHERE name IS NULL OR name = ''"
    
    # Make the name field not null
    change_column_null :user_profiles, :name, false
  end

  def down
    change_column_null :user_profiles, :name, true
  end
end
