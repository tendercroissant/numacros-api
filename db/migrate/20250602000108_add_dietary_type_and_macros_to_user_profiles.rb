class AddDietaryTypeAndMacrosToUserProfiles < ActiveRecord::Migration[8.0]
  def change
    add_column :user_profiles, :dietary_type, :integer, default: 0, null: false
    add_column :user_profiles, :custom_carbs_percent, :float
    add_column :user_profiles, :custom_protein_percent, :float
    add_column :user_profiles, :custom_fat_percent, :float
    
    # Add index for dietary_type for performance
    add_index :user_profiles, :dietary_type
  end
end
