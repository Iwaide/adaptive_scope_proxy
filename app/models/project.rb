class Project < ApplicationRecord
  belongs_to :user
  has_many :tasks, dependent: :destroy
  has_many :labels, dependent: :destroy

  enum :status, { draft: 0, active: 1, on_hold: 2, completed: 3, canceled: 4 }

  scope :active, -> { where(status: :active, archived_at: nil) }
  scope :latest_by_user, -> {
    ranked = select(<<~SQL.squish)
      projects.*,
      ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY due_on DESC) AS row_number
    SQL

    from("(#{ranked.to_sql}) AS projects").where(row_number: 1)
  }
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

  def self.latest_by_user_filtering(records)
    records.sort_by { [ it.user_id, -it.due_on.to_i ] }
            .uniq { |rec| rec.user_id }
  end

  def risk_labels
    labels.filter(&:high_risk?)
  end

  def with_active_labels?
    labels.any?(&:active?)
  end
end
