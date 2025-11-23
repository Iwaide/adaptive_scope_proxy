# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2024_11_10_120200) do
  create_table "labels", force: :cascade do |t|
    t.datetime "archived_at"
    t.boolean "billable", default: false, null: false
    t.string "category"
    t.string "color"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.integer "project_id", null: false
    t.string "risk_level"
    t.datetime "updated_at", null: false
    t.index ["archived_at"], name: "index_labels_on_archived_at"
    t.index ["category"], name: "index_labels_on_category"
    t.index ["project_id"], name: "index_labels_on_project_id"
    t.index ["risk_level"], name: "index_labels_on_risk_level"
  end

  create_table "projects", force: :cascade do |t|
    t.datetime "archived_at"
    t.bigint "budget_cents", default: 0, null: false
    t.datetime "created_at", null: false
    t.date "due_on"
    t.string "name", null: false
    t.string "risk_level", default: "medium", null: false
    t.string "status", default: "draft", null: false
    t.datetime "updated_at", null: false
    t.index ["archived_at"], name: "index_projects_on_archived_at"
    t.index ["risk_level"], name: "index_projects_on_risk_level"
    t.index ["status"], name: "index_projects_on_status"
  end

  create_table "tasks", force: :cascade do |t|
    t.boolean "billable", default: false, null: false
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.date "due_on"
    t.integer "estimate_minutes", default: 0, null: false
    t.string "kind"
    t.integer "label_id"
    t.string "priority", default: "normal", null: false
    t.integer "project_id", null: false
    t.string "state", default: "planned", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.integer "worked_minutes", default: 0, null: false
    t.index ["completed_at"], name: "index_tasks_on_completed_at"
    t.index ["due_on"], name: "index_tasks_on_due_on"
    t.index ["label_id"], name: "index_tasks_on_label_id"
    t.index ["priority"], name: "index_tasks_on_priority"
    t.index ["project_id"], name: "index_tasks_on_project_id"
    t.index ["state"], name: "index_tasks_on_state"
  end

  add_foreign_key "labels", "projects"
  add_foreign_key "tasks", "labels"
  add_foreign_key "tasks", "projects"
end
