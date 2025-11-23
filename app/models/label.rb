class Label < ApplicationRecord
  belongs_to :project
  has_many :tasks

  scope :by_category, ->(category) { where(category: category) }
  scope :warm_colors, -> { where(color: %w[red orange yellow]) }
  scope :active, -> { where(archived_at: nil) }
  scope :billable_only, -> { active.where(billable: true) }
  scope :risk_flags, -> {
    active.where(category: "risk").where(risk_level: %w[high critical])
  }
  scope :applied_to_billable_tasks, -> {
    joins(:tasks).merge(Task.billable).distinct
  }
end
