class MigrateWeightToSeparateTable < ActiveRecord::Migration[8.0]
  def up
    # Migrate existing weight data using Rails methods for better compatibility
    say_with_time "Migrating weight data to weights table" do
      # Use connection.execute with proper PostgreSQL syntax
      connection.execute <<-SQL
        INSERT INTO weights (user_id, weight_kg, recorded_at, created_at, updated_at)
        SELECT 
          up.user_id,
          up.weight_kg,
          up.updated_at as recorded_at,
          CURRENT_TIMESTAMP as created_at,
          CURRENT_TIMESTAMP as updated_at
        FROM user_profiles up
        WHERE up.weight_kg IS NOT NULL;
      SQL
    end
    
    # Remove weight_kg column from user_profiles
    remove_column :user_profiles, :weight_kg
  end
  
  def down
    # Add weight_kg column back to user_profiles
    add_column :user_profiles, :weight_kg, :float, comment: "Weight in kilograms"
    
    say_with_time "Restoring weight data to user_profiles" do
      # Use PostgreSQL's DISTINCT ON for efficiency
      connection.execute <<-SQL
        UPDATE user_profiles 
        SET weight_kg = w.weight_kg
        FROM (
          SELECT DISTINCT ON (user_id) 
            user_id, 
            weight_kg
          FROM weights 
          ORDER BY user_id, recorded_at DESC
        ) w
        WHERE user_profiles.user_id = w.user_id;
      SQL
    end
    
    # Make weight_kg not null after data migration
    change_column_null :user_profiles, :weight_kg, false
  end
end
