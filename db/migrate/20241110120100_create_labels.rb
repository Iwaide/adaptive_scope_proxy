class CreateLabels < ActiveRecord::Migration[8.1]
  def change
    create_table :labels do |t|
      t.references :project, null: false, foreign_key: true
      t.string :name, null: false
      t.integer :category
      t.string :color
      t.integer :risk_level
      t.boolean :billable, null: false, default: false
      t.datetime :archived_at

      t.timestamps
    end

    add_index :labels, :category
    add_index :labels, :risk_level
    add_index :labels, :archived_at
  end
end
