FactoryBot.define do
  factory :label do
    association :project
    sequence(:name) { |n| "ラベル#{n}" }
    category { :feature }
    color { "blue" }
    risk_level { :medium }
    billable { false }

    trait :active do
      archived_at { nil }
    end

    trait :risk_flag do
      category { :risk }
      risk_level { :high }
    end

    trait :billable_only do
      billable { true }
    end
  end
end
