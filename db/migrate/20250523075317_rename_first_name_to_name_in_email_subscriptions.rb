class RenameFirstNameToNameInEmailSubscriptions < ActiveRecord::Migration[8.0]
  def change
    rename_column :email_subscriptions, :first_name, :name
  end
end
