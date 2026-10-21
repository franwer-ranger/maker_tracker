# Versión del contenido editable (MT-37): sube solo cuando alguien edita
# título, cuerpo o propiedades (historias), título u objetivo (hitos) o el
# brief. Mover, reordenar o cerrar no la tocan.
class AddVersionToEditableContent < ActiveRecord::Migration[8.1]
  def change
    add_column :stories, :version, :integer, null: false, default: 1
    add_column :milestones, :version, :integer, null: false, default: 1
    add_column :projects, :brief_version, :integer, null: false, default: 1
  end
end
