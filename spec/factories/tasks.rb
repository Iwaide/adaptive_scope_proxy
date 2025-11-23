FactoryBot.define do
  factory :task do
    association :project
    label { association :label, project: project }
    sequence(:title) { |n| "タスク#{n}" }
    state { "planned" }
    priority { "normal" }
    estimate_minutes { 60 }
    worked_minutes { 0 }
    billable { false }
    due_on { Date.current + 1.day }

    trait :billable do
      billable { true }
    end

    trait :overdue do
      due_on { Date.yesterday }
      completed_at { nil }
    end

    trait :slipping do
      priority { "high" }
      estimate_minutes { 100 }
      worked_minutes { 90 }
      completed_at { nil }
    end
  end
end
