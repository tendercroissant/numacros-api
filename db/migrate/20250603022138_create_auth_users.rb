class CreateAuthUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :auth_users do |t|
      t.string :email
      t.string :password_digest

      t.timestamps
    end
    add_index :auth_users, :email, unique: true
  end
end
