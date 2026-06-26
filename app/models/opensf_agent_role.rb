class OpensfAgentRole < ApplicationRecord
  belongs_to :account
  belongs_to :user

  enum :role, { vendor: 0, supervisor: 1, manager: 2 }

  validates :user_id, uniqueness: { scope: :account_id }
end
