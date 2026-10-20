# QA pendiente (MT-32): lo que Fran aún no ha probado de lo que ya está Hecho.
# Es la marca de una historia que pasa a Hecha cuando esto existe (pending),
# y cómo acabó (passed | failed). Nulo en las que ya estaban hechas antes: no
# entran como pendientes. No es un estado de la historia ni bloquea nada.
class AddQaToStories < ActiveRecord::Migration[8.1]
  def change
    add_column :stories, :qa, :string
    add_index :stories, :qa, where: "qa IS NOT NULL"
  end
end
