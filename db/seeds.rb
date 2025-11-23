require "securerandom"

puts "Seeding data for scope checks…"

SEED_BULK_PROJECTS = ENV.fetch("SEED_BULK_PROJECTS", 10_000).to_i
SEED_BULK_TASKS_PER_PROJECT = ENV.fetch("SEED_BULK_TASKS_PER_PROJECT", 2).to_i.clamp(1, 5)

def build_task_attrs(project, label: nil, billable: false, overdue: false, slipping: false)
  due_on = overdue ? Date.current - rand(1..10) : Date.current + rand(1..30)
  estimate = slipping ? rand(60..180) : rand(30..120)
  worked = slipping ? (estimate * 0.9).to_i : rand(0..(estimate * 0.7).to_i)

  {
    project_id: project.id,
    label_id: label&.id,
    title: "Task #{SecureRandom.hex(4)}",
    priority: slipping ? "high" : "normal",
    state: "planned",
    estimate_minutes: estimate,
    worked_minutes: worked,
    billable: billable,
    due_on: due_on,
    completed_at: nil,
    created_at: Time.current,
    updated_at: Time.current
  }
end

def ensure_scope_sample_projects
  puts "Creating small scenario set..."

  # Needs attention (active + overdue/slipping tasks + risk labels + billable)
  3.times do |i|
    project = Project.find_or_create_by!(name: "Needs Attention #{i + 1}") do |p|
      p.status = "active"
      p.risk_level = "medium"
      p.budget_cents = 500_000
      p.due_on = Date.current + 7.days
    end

    risk_label = project.labels.find_or_create_by!(name: "Risk Label #{i + 1}") do |l|
      l.category = "risk"
      l.risk_level = "high"
      l.billable = true
      l.archived_at = nil
      l.color = "red"
    end

    tasks = []
    tasks << build_task_attrs(project, label: risk_label, billable: true, overdue: true)
    tasks << build_task_attrs(project, label: risk_label, billable: true, slipping: true)
    Task.insert_all!(tasks) if tasks.any?
  end

  # Healthy (active + low risk + on-track tasks)
  3.times do |i|
    project = Project.find_or_create_by!(name: "Healthy #{i + 1}") do |p|
      p.status = "active"
      p.risk_level = "low"
      p.budget_cents = 250_000
      p.due_on = Date.current + 30.days
    end

    label = project.labels.find_or_create_by!(name: "General Label #{i + 1}") do |l|
      l.category = "feature"
      l.risk_level = "low"
      l.billable = false
      l.archived_at = nil
      l.color = "blue"
    end

    tasks = []
    tasks << build_task_attrs(project, label: label, billable: false, overdue: false, slipping: false)
    tasks << build_task_attrs(project, label: label, billable: false, overdue: false, slipping: false)
    Task.insert_all!(tasks) if tasks.any?
  end

  # Applied-to-billable labels without risk flags
  2.times do |i|
    project = Project.find_or_create_by!(name: "Billable Labels #{i + 1}") do |p|
      p.status = "active"
      p.risk_level = "medium"
      p.budget_cents = 150_000
      p.due_on = Date.current + 14.days
    end

    label = project.labels.find_or_create_by!(name: "Billable Label #{i + 1}") do |l|
      l.category = "feature"
      l.risk_level = "medium"
      l.billable = true
      l.archived_at = nil
      l.color = "green"
    end

    tasks = []
    tasks << build_task_attrs(project, label: label, billable: true, overdue: false, slipping: false)
    Task.insert_all!(tasks) if tasks.any?
  end
end

def seed_bulk_projects
  existing_bulk = Project.where("name LIKE ?", "Bulk Project %").count
  remaining = [SEED_BULK_PROJECTS - existing_bulk, 0].max
  return puts "Bulk projects already present (#{existing_bulk}). Skipping bulk seed." if remaining.zero?

  puts "Creating #{remaining} bulk projects with #{SEED_BULK_TASKS_PER_PROJECT} tasks each..."

  created_projects = []
  remaining.times do |i|
    created_projects << Project.create!(
      name: "Bulk Project #{existing_bulk + i + 1}",
      status: "active",
      risk_level: %w[low medium high].sample,
      budget_cents: rand(50_000..500_000),
      due_on: Date.current + rand(5..90),
      created_at: Time.current,
      updated_at: Time.current
    )
  end

  created_projects.each_slice(200) do |projects|
    task_rows = []

    projects.each do |project|
      label = project.labels.create!(
        name: "Bulk Label #{project.id}",
        category: "feature",
        risk_level: "medium",
        billable: [true, false].sample,
        archived_at: nil,
        color: "gray"
      )

      SEED_BULK_TASKS_PER_PROJECT.times do
        billable = [true, false].sample
        overdue = [true, false].sample
        slipping = [true, false].sample
        task_rows << build_task_attrs(project, label: label, billable: billable, overdue: overdue, slipping: slipping)
      end
    end

    Task.insert_all!(task_rows) if task_rows.any?
  end
end

ActiveRecord::Base.transaction do
  ensure_scope_sample_projects
  seed_bulk_projects
end

puts "Seed complete."
