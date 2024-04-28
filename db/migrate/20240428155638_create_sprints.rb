class CreateSprints < ActiveRecord::Migration[7.1]
  def change
    create_table :sprints do |t|
      t.date :start_date
      t.date :end_date
      t.integer :length
      t.integer :velocity
      t.integer :strength
      t.references :project, null: false, foreign_key: true

      t.timestamps
    end
  end
end
