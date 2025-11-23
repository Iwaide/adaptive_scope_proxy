class Task < ApplicationRecord
  belongs_to :project
  belongs_to :label, optional: true

  enum :state, { planned: 0, in_progress: 1, blocked: 2, done: 3 }
  enum :priority, { low: 0, normal: 1, high: 2, urgent: 3 }, prefix: true

  scope :billable, -> { where(billable: true) }
  scope :overdue, -> { where(completed_at: nil).where(due_on: ..Date.current) }
  scope :slipping, -> {
    priority_high
      .where(estimate_minutes: 0..)
      .where("worked_minutes >= estimate_minutes * 0.8")
      .where(completed_at: nil)
  }
end
