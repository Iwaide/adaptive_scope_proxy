FactoryBot.define do
  factory :project do
    association :user
    sequence(:name) { |n| "プロジェクト#{n}" }
    status { "active" }
    risk_level { "medium" }
    budget_cents { 100_000 }
    due_on { Date.current + 7.days }

    trait :draft do
      status { "draft" }
    end

    trait :low_risk do
      risk_level { "low" }
    end

    trait :archived do
      archived_at { Time.current }
    end

    trait :with_active_labels do
      after(:create) do |project|
        create(:label, :active, project: project)
      end
    end
  end
end
