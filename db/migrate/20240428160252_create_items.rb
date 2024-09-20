class CreateItems < ActiveRecord::Migration[7.1]
  def change
    create_table :items do |t|
      t.integer :status
      t.integer :kind
      t.boolean :icebox, default: true
      t.boolean :in_progress, default: false
      t.boolean :done, default: false
      t.boolean :backlog, default: false
      t.string :name
      t.text :description
      t.integer :points, default: nil
      t.integer :position, null: false
      t.datetime :accepted_at
      t.datetime :started_at
      t.datetime :finished_at
      t.datetime :delivered_at

      t.references :user, null: true, foreign_key: true
      t.references :sprint, null: true, foreign_key: true
      t.references :project, null: false, foreign_key: true
      t.timestamps
    end
  end
end
