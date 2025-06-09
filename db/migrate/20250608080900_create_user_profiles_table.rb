class CreateUserProfilesTable < ActiveRecord::Migration[8.0]
  def change
    create_table :user_profiles do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.integer :sex, null: false
      t.date :birth_date, null: false
      t.decimal :height_cm, precision: 5, scale: 1, null: false

      t.timestamps
    end
  end
end
