class CreateProjects < ActiveRecord::Migration[7.1]
  def change
    create_table :projects do |t|
      t.string :name
      t.text :description
      t.date :start_date
      t.integer :velocity
      t.integer :velocity_override
      t.integer :volatility
      t.integer :sprint_length

      t.timestamps
    end
  end
end
