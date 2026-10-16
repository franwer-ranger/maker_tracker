# Quién hace qué (historia #004): actores, decisiones y comentarios.
class CreateActorsDecisionsComments < ActiveRecord::Migration[8.1]
  def change
    create_table :actors do |t|
      t.string :name, null: false, index: { unique: true }
      t.string :kind, null: false
      t.string :token_digest
      t.timestamps
    end
    add_foreign_key :stories, :actors, column: :claimed_by_id

    # Último número de decisión asignado, como last_story_number.
    add_column :projects, :last_decision_number, :integer, null: false, default: 0

    create_table :decisions do |t|
      t.references :project, null: false, foreign_key: true
      t.references :story, foreign_key: true
      t.references :actor, null: false, foreign_key: true
      t.references :supersedes, foreign_key: { to_table: :decisions }
      t.integer :number, null: false
      t.string :title, null: false
      t.text :body, null: false, default: ""
      t.timestamps
      t.index %i[project_id number], unique: true
    end

    create_table :comments do |t|
      t.references :story, null: false, foreign_key: true
      t.references :actor, null: false, foreign_key: true
      t.text :body, null: false
      t.timestamps
    end
  end
end
