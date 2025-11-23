class CreateTasks < ActiveRecord::Migration[8.1]
  def change
    create_table :tasks do |t|
      t.references :project, null: false, foreign_key: true
      t.references :label, foreign_key: true
      t.string :title, null: false
      t.string :state, null: false, default: "planned"
      t.string :priority, null: false, default: "normal"
      t.integer :estimate_minutes, null: false, default: 0
      t.integer :worked_minutes, null: false, default: 0
      t.string :kind
      t.date :due_on
      t.boolean :billable, null: false, default: false
      t.datetime :completed_at

      t.timestamps
    end

    add_index :tasks, :state
    add_index :tasks, :priority
    add_index :tasks, :due_on
    add_index :tasks, :completed_at
  end
end
