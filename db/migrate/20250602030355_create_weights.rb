class CreateWeights < ActiveRecord::Migration[8.0]
  def change
    create_table :weights do |t|
      t.references :user, null: false, foreign_key: true
      t.float :weight_kg, null: false, comment: "Weight in kilograms"
      t.datetime :recorded_at, null: false, comment: "When the weight was recorded"

      t.timestamps
    end
    
    add_index :weights, [:user_id, :recorded_at], name: "index_weights_on_user_and_recorded_at"
    add_index :weights, :recorded_at
  end
end
