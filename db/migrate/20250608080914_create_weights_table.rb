class CreateWeightsTable < ActiveRecord::Migration[8.0]
  def change
    create_table :weights do |t|
      t.references :user, null: false, foreign_key: true
      t.decimal :weight_kg, precision: 5, scale: 1, null: false
      t.datetime :recorded_at, null: false

      t.timestamps
    end

    add_index :weights, [:user_id, :recorded_at], unique: true
    add_index :weights, :recorded_at
  end
end
