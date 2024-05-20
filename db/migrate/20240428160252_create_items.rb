class CreateItems < ActiveRecord::Migration[7.1]
  def change
    create_table :items do |t|
      t.integer :status
      t.integer :kind
      t.boolean :icebox
      t.string :name
      t.text :description
      t.integer :points

      t.references :user, null: false, foreign_key: true
      t.references :sprint, null: true, foreign_key: true
      t.references :project, null: false, foreign_key: true

      t.timestamps
    end
  end
end
