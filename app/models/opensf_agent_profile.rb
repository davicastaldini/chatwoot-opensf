# OPENSF: per-agent settings (broker code for Corbee production reports)
class OpensdfAgentProfile < ApplicationRecord
  self.table_name = 'opensf_agent_profiles'

  belongs_to :user

  validates :codigo_corretor, length: { maximum: 50 }, allow_blank: true
end
