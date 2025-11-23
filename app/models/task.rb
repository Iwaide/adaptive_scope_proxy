class Task < ApplicationRecord
  belongs_to :project
  belongs_to :label, optional: true

  enum state: { planned: 0, in_progress: 1, blocked: 2, done: 3 }
  enum priority: { low: 0, normal: 1, high: 2, urgent: 3 }

  scope :billable, -> { where(billable: true) }
  scope :for_kind, ->(kind) { where(kind: kind) }
  scope :for_label, ->(label_id) { where(label_id: label_id) }
  scope :due_within, ->(range) { where(due_on: range) }
  scope :overdue, -> { where(completed_at: nil).where("due_on < ?", Date.current) }
  scope :slipping, -> {
    high_priority
      .where("estimate_minutes > 0")
      .where("worked_minutes >= estimate_minutes * 0.8")
      .where(completed_at: nil)
  }
  scope :long_running, ->(minutes = 240) { where("worked_minutes >= ?", minutes) }
  scope :on_track, -> {
    where(completed_at: nil)
      .where.not(state: :blocked)
      .where("COALESCE(worked_minutes, 0) <= COALESCE(estimate_minutes, 0) * 1.1")
  }
end
