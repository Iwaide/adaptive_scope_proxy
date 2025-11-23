class Task < ApplicationRecord
  belongs_to :project
  belongs_to :label, optional: true

  enum :state, { planned: 0, in_progress: 1, blocked: 2, done: 3 }
  enum :priority, { low: 0, normal: 1, high: 2, urgent: 3 }, prefix: true
end
