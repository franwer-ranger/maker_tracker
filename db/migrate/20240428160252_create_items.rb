class CreateItems < ActiveRecord::Migration[7.1]
  def change
    create_table :items do |t|
      t.integer :status
      t.integer :kind
      t.boolean :icebox, default: true
      t.string :name
      t.text :description
      t.integer :points, default: nil
      t.integer :position, null: false

      t.references :user, null: false, foreign_key: true
      t.references :sprint, null: true, foreign_key: true
      t.references :project, null: false, foreign_key: true

      t.timestamps
    end
  end
end
