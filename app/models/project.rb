class Project < ApplicationRecord
  has_many :tasks, dependent: :destroy
  has_many :labels, dependent: :destroy

  enum :status, { draft: 0, active: 1, on_hold: 2, completed: 3, canceled: 4 }

  scope :active, -> { where(status: :active, archived_at: nil) }
  scope :needs_attention, -> {
    active
      .joins(:tasks)
      .merge(Task.overdue.or(Task.slipping))
      .distinct
  }
  scope :healthy, -> {
    active
      .left_outer_joins(:tasks)
      .merge(Task.on_track)
      .where(risk_level: "low")
      .distinct
  }
end
