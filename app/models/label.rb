class Label < ApplicationRecord
  belongs_to :project
  has_many :tasks
  enum :category, { feature: 0, bug: 1, documentation: 2, risk: 3 }, prefix: true
  enum :risk_level, { low: 0, medium: 1, high: 2, critical: 3 }, prefix: true
end
