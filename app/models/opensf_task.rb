# OPENSF: tarefa/retorno da agenda
class OpensfTask < ApplicationRecord
  self.table_name = 'opensf_tasks'

  STATUSES = %w[pending done cancelled].freeze

  belongs_to :account
  belongs_to :assignee, class_name: 'User'
  belongs_to :created_by, class_name: 'User'
  belongs_to :conversation, optional: true
  belongs_to :contact, optional: true

  validates :title, presence: true
  validates :due_at, presence: true
  validates :status, inclusion: { in: STATUSES }

  scope :pending, -> { where(status: 'pending') }
  scope :for_assignee, ->(user_id) { where(assignee_id: user_id) }
  scope :due_on, ->(date) { where(due_at: date.beginning_of_day..date.end_of_day) }
  scope :overdue, -> { pending.where('due_at < ?', Time.current.beginning_of_day) }

  def mark_done!
    update!(status: 'done', completed_at: Time.current)
  end
end
