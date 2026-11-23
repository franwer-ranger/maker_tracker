# Páginas de documentación (MT-89): portada, capacidades y transversales, en
# markdown y con versión (MT-37). La portada es el brief (D-92): cada proyecto
# se queda con una portada que lleva su brief y su versión de hoy. Las columnas
# `projects.brief` y `brief_version` no se borran (el modelo las ignora): así la
# migración no reescribe la tabla de proyectos y `down` puede devolver el brief.
class CreatePages < ActiveRecord::Migration[8.1]
  def up
    create_table :pages do |t|
      t.references :project, null: false, foreign_key: true
      t.string :kind, null: false
      t.string :slug, null: false
      t.string :title, null: false
      t.string :icon
      t.string :area
      t.text :body, null: false, default: ""
      t.integer :version, null: false, default: 1
      t.timestamps
    end
    add_index :pages, [ :project_id, :slug ], unique: true
    add_index :pages, :project_id, unique: true, where: "kind = 'cover'", name: "index_pages_on_project_id_one_cover"

    execute <<~SQL
      INSERT INTO pages (project_id, kind, slug, title, body, version, created_at, updated_at)
      SELECT id, 'cover', 'cover', name, brief, brief_version, created_at, updated_at FROM projects
    SQL
  end

  def down
    execute <<~SQL
      UPDATE projects SET
        brief = COALESCE((SELECT body FROM pages WHERE pages.project_id = projects.id AND kind = 'cover'), brief),
        brief_version = COALESCE((SELECT version FROM pages WHERE pages.project_id = projects.id AND kind = 'cover'), brief_version)
    SQL
    drop_table :pages
  end
end
