# Cuándo miró Fran por última vez la portada (story_id nulo) y cada historia
# (MT-31). No hay login ni modelo de usuarios: hay un solo humano, así que basta
# una fila por pantalla. No es un evento: mirar no cambia nada del producto.
class CreateVisits < ActiveRecord::Migration[8.1]
  def change
    create_table :visits do |t|
      t.references :story, foreign_key: true, index: { unique: true } # nulo: la portada
      t.datetime :since, null: false # desde cuándo cuenta lo que se enseña
      t.datetime :seen_at, null: false # la última vez que se abrió

      t.timestamps
    end
  end
end
