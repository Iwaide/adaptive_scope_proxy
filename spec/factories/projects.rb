FactoryBot.define do
  factory :project do
    sequence(:name) { |n| "プロジェクト#{n}" }
    status { "active" }
    risk_level { "medium" }
    budget_cents { 100_000 }
    due_on { Date.current + 7.days }

    trait :low_risk do
      risk_level { "low" }
    end

    trait :archived do
      archived_at { Time.current }
    end
  end
end
