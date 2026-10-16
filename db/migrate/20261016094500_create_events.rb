# Registro de los hechos (historia #005). Solo se añaden filas.
class CreateEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :events do |t|
      t.references :project, null: false, foreign_key: true
      t.references :story, foreign_key: true
      t.references :actor, null: false, foreign_key: true
      t.string :action, null: false
      t.json :data, null: false, default: {}
      t.text :reason
      t.datetime :occurred_at, null: false
      t.datetime :created_at, null: false
      t.index %i[project_id occurred_at]
      t.index %i[story_id occurred_at]
    end
  end
end
