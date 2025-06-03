class RemoveGenderIndexFromUserProfiles < ActiveRecord::Migration[8.0]
  def change
    remove_index :user_profiles, :gender
  end
end
