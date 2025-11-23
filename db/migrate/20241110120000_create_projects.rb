class CreateProjects < ActiveRecord::Migration[8.1]
  def change
    create_table :projects do |t|
      t.string :name, null: false
      t.integer :status, null: false, default: 0
      t.string :risk_level, null: false, default: "medium"
      t.bigint :budget_cents, null: false, default: 0
      t.date :due_on
      t.datetime :archived_at

      t.timestamps
    end

    add_index :projects, :status
    add_index :projects, :risk_level
    add_index :projects, :archived_at
  end
end
