class Label < ApplicationRecord
  belongs_to :project
  has_many :tasks

  scope :active, -> { where(archived_at: nil) }
  scope :risk_flags, -> {
    active.where(category: "risk").where(risk_level: %w[high critical])
  }
  scope :applied_to_billable_tasks, -> {
    joins(:tasks).merge(Task.billable).distinct
  }
end
