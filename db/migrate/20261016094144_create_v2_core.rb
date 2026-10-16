# Núcleo del modelo v2 (historia #003): proyectos, hitos e historias.
class CreateV2Core < ActiveRecord::Migration[8.1]
  def change
    create_table :projects do |t|
      t.string :name, null: false
      t.string :slug, null: false, index: { unique: true }
      t.string :key, null: false, index: { unique: true }
      t.text :brief, null: false, default: ""
      t.json :settings, null: false, default: {}
      # Último número asignado: los números de historia no se reutilizan nunca.
      t.integer :last_story_number, null: false, default: 0
      t.timestamps
    end

    create_table :milestones do |t|
      t.references :project, null: false, foreign_key: true
      t.string :title, null: false
      t.text :goal, null: false, default: ""
      t.integer :position, null: false
      t.datetime :closed_at
      t.timestamps
      t.index %i[project_id position], unique: true
    end

    create_table :stories do |t|
      t.references :project, null: false, foreign_key: true
      t.references :milestone, foreign_key: true
      t.integer :number, null: false
      t.string :title, null: false
      t.text :body, null: false, default: ""
      t.json :properties, null: false, default: {}
      t.string :state, null: false, default: "idea"
      t.integer :position, null: false
      # La tabla actors llega en la #004, que añade la clave ajena.
      t.references :claimed_by, index: true
      t.datetime :claimed_at
      t.timestamps
      t.index %i[project_id number], unique: true
      t.index %i[project_id milestone_id position], unique: true
      t.index %i[project_id state]
    end
  end
end
