class MakeGenderAndBirthDateRequired < ActiveRecord::Migration[8.0]
  def change
    # Set defaults for existing records
    execute "UPDATE user_profiles SET gender = 1 WHERE gender IS NULL"
    execute "UPDATE user_profiles SET birth_date = '1990-01-01' WHERE birth_date IS NULL"
    
    change_column_null :user_profiles, :gender, false
    change_column_null :user_profiles, :birth_date, false
  end
end
