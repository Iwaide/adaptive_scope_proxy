class Task < ApplicationRecord
  belongs_to :project
  belongs_to :label, optional: true

  enum :state, { planned: 0, in_progress: 1, blocked: 2, done: 3 }
  enum :priority, { low: 0, normal: 1, high: 2, urgent: 3 }, prefix: true

  scope :billable, -> { where("#{table_name}.billable = ?", true) }
  scope :overdue, -> {
    where("#{table_name}.completed_at IS NULL")
      .where("#{table_name}.due_on <= ?", Date.current)
  }
  scope :slipping, -> {
    priority_high
      .where("#{table_name}.estimate_minutes > 0")
      .where("#{table_name}.worked_minutes >= #{table_name}.estimate_minutes * 0.8")
      .where("#{table_name}.completed_at IS NULL")
  }
end
