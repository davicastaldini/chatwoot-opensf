class CreateOpensfAgentRoles < ActiveRecord::Migration[7.1]
  def change
    create_table :opensf_agent_roles do |t|
      t.references :account, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :role, null: false, default: 0

      t.timestamps
    end

    add_index :opensf_agent_roles, [:account_id, :user_id], unique: true
  end
end
