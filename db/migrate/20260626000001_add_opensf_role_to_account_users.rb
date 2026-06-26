class AddOpensfRoleToAccountUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :account_users, :opensf_role, :string, null: true
  end
end
