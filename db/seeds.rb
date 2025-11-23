puts "Seeding data tuned for Projects#index filters…"

TARGET_MATCHING = ENV.fetch("SEED_MATCHING_PROJECTS", 10_000).to_i
TARGET_NON_MATCHING = ENV.fetch("SEED_NON_MATCHING_PROJECTS", 10_000).to_i
TARGET_VALID_LATEST = ENV.fetch("SEED_VALID_LATEST_PROJECTS", 10_000).to_i

def reset_tables
  puts "Resetting tables..."
  Task.delete_all
  Label.delete_all
  Project.delete_all
end

def create_matching_projects
  puts "Creating #{TARGET_MATCHING} matching projects (active + risk flag labels + slipping tasks)..."

  TARGET_MATCHING.times do |i|
    project = Project.create!(
      name: "Matching Project #{i + 1}",
      status: "active",
      risk_level: "medium",
      budget_cents: 300_000,
      due_on: Date.current + 30.days,
      archived_at: nil
    )

    label = project.labels.create!(
      name: "Risk Label #{i + 1}",
      category: "risk",
      risk_level: "high",
      billable: true,
      archived_at: nil,
      color: "red"
    )

    project.tasks.create!(
      label: label,
      title: "Slipping Task #{i + 1}",
      state: "in_progress",
      priority: "high",
      estimate_minutes: 120,
      worked_minutes: 110,
      billable: true,
      due_on: Date.current + 10.days,
      completed_at: nil
    )
  end
end

def create_valid_latest_projects_for
  puts "Creating #{TARGET_VALID_LATEST} projects that match Project.valid_latest_projects_for..."

  TARGET_VALID_LATEST.times do |i|
    project = Project.create!(
      name: "Latest-Eligible Project #{i + 1}",
      status: "active",
      risk_level: "level_#{i + 1}",
      budget_cents: 200_000,
      due_on: Date.current - (i % 30),
      archived_at: nil
    )

    project.labels.create!(
      name: "Safe Label #{i + 1}",
      category: "feature",
      risk_level: "low",
      billable: false,
      archived_at: nil,
      color: "green"
    )

    project.tasks.create!(
      title: "Open Task #{i + 1}",
      state: "in_progress",
      priority: "normal",
      estimate_minutes: 60,
      worked_minutes: 30,
      billable: false,
      due_on: Date.current - (i % 7),
      completed_at: nil
    )
  end
end

def create_non_matching_projects
  puts "Creating #{TARGET_NON_MATCHING} non-matching projects..."

  TARGET_NON_MATCHING.times do |i|
    project = Project.create!(
      name: "Other Project #{i + 1}",
      status: "draft",
      risk_level: "low",
      budget_cents: 150_000,
      due_on: Date.current + 45.days,
      archived_at: nil
    )

    label = project.labels.create!(
      name: "Feature Label #{i + 1}",
      category: "feature",
      risk_level: "low",
      billable: false,
      archived_at: nil,
      color: "blue"
    )

    project.tasks.create!(
      label: label,
      title: "On Track Task #{i + 1}",
      state: "planned",
      priority: "normal",
      estimate_minutes: 90,
      worked_minutes: 30,
      billable: false,
      due_on: Date.current + 20.days,
      completed_at: nil
    )
  end
end

ActiveRecord::Base.transaction do
  reset_tables
  create_matching_projects
  create_valid_latest_projects_for
  create_non_matching_projects
end

puts "Seed complete. Matching projects: #{TARGET_MATCHING}, non-matching: #{TARGET_NON_MATCHING}."
