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
  def self.latest_by_user_filter(records)
    records.sort_by { [ it.user_id, -it.due_on.to_time.to_i ] }
            .uniq { |rec| rec.user_id }
  end

  def with_active_labels?
    labels.any?(&:active?)
  end
end
