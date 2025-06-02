class CreateMacronutrientTargets < ActiveRecord::Migration[8.0]
  def change
    create_table :macronutrient_targets do |t|
      t.references :user_profile, null: false, foreign_key: true, index: { unique: true }
      t.integer :calories, null: false
      t.integer :carbs_grams, null: false
      t.integer :protein_grams, null: false
      t.integer :fat_grams, null: false

      t.timestamps
    end
  end
end
