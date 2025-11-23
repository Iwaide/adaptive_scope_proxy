class Label < ApplicationRecord
  belongs_to :project
  has_many :tasks
  enum :category, { feature: 0, bug: 1, documentation: 2, risk: 3 }, prefix: true
  enum :risk_level, { low: 0, medium: 1, high: 2, critical: 3 }, prefix: true

  scope :active, -> { where(archived_at: nil) }
  scope :risk_flags, -> {
    active.where(category: "risk").where(risk_level: %w[high critical])
  }
  scope :applied_to_billable_tasks, -> {
    joins(:tasks).merge(Task.billable).distinct
  }
end
