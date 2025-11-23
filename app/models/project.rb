class Project < ApplicationRecord
  has_many :tasks, dependent: :destroy
  has_many :labels, dependent: :destroy

  enum :status, { draft: 0, active: 1, on_hold: 2, completed: 3, canceled: 4 }

  scope :active, -> { where(status: :active, archived_at: nil) }
  scope :with_active_labels, -> {
    joins(:labels)
      .where(labels: { archived_at: nil })
      .distinct
  }
  scope :with_risk_flag_labels, -> {
    with_active_labels.where(labels: { category: "risk", risk_level: %w[high critical] })
  }
  scope :with_billable_labels, -> {
    joins(labels: :tasks)
      .where(tasks: { billable: true })
      .distinct
  }
  scope :with_billable_tasks, -> {
    joins(:tasks)
      .where(tasks: { billable: true })
      .distinct
  }
  scope :with_overdue_tasks, -> {
    joins(:tasks)
      .where(tasks: { completed_at: nil })
      .where("#{Task.table_name}.due_on <= ?", Date.current)
      .distinct
  }
  scope :with_slipping_tasks, -> {
    joins(:tasks)
      .where(tasks: { priority: Task.priorities[:high] })
      .where("#{Task.table_name}.estimate_minutes > 0")
      .where("#{Task.table_name}.worked_minutes >= #{Task.table_name}.estimate_minutes * 0.8")
      .where(tasks: { completed_at: nil })
      .distinct
  }
  scope :needs_attention, -> {
    active.merge(with_overdue_tasks.or(with_slipping_tasks))
  }
  scope :healthy, -> {
    active
      .left_outer_joins(:tasks)
      .where(risk_level: "low")
      .where(tasks: { completed_at: nil })
      .where.not(tasks: { state: :blocked })
      .where("COALESCE(tasks.worked_minutes, 0) <= COALESCE(tasks.estimate_minutes, 0) * 1.1")
      .distinct
  }

  def self.valid_latest_projects_for(date: Date.current, exclude_label_id: nil)
    relation = includes(labels: :tasks)
      .left_outer_joins(:labels, :tasks)
      .active
      .where(due_on: ..date)
      .where(tasks: { completed_at: nil })

    relation = relation.where.not(labels: { id: exclude_label_id }) if exclude_label_id.present?

    relation
      .distinct
      .reject { |project| project.labels.any?(&:high_risk?) }
      .group_by(&:risk_level)
      .transform_values { |projects| projects.max_by { |project| project.due_on || Date.new(9999, 12, 31) } }
      .values
  end

  def risk_labels
    labels.filter(&:high_risk?)
  end
end
