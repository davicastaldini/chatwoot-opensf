# OPENSF: stores per-agent settings not present in core Chatwoot
class CreateOpensdfAgentProfiles < ActiveRecord::Migration[7.1]
  def change
    create_table :opensf_agent_profiles do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.string :codigo_corretor, limit: 50
      t.timestamps
    end
  end
end
