class AddGenderToUserProfiles < ActiveRecord::Migration[8.0]
  def change
    add_column :user_profiles, :gender, :integer, comment: "0: male, 1: female"
    add_index :user_profiles, :gender
  end
end
