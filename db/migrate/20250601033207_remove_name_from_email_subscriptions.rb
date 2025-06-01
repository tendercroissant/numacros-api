class RemoveNameFromEmailSubscriptions < ActiveRecord::Migration[8.0]
  def change
    remove_column :email_subscriptions, :name, :string
  end
end
