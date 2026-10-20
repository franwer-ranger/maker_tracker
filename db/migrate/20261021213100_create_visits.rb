# Cuándo miró Fran por última vez la portada (story_id nulo) y cada historia
# (MT-31). No hay login ni modelo de usuarios: hay un solo humano, así que basta
# una fila por pantalla. No es un evento: mirar no cambia nada del producto.
class CreateVisits < ActiveRecord::Migration[8.1]
  def change
    create_table :visits do |t|
      t.string :key, null: false, index: { unique: true } # "home" o "story-12": SQLite no ve únicos los NULL
      t.references :story, foreign_key: true # nulo: la portada
      t.datetime :since, null: false # desde cuándo cuenta lo que se enseña
      t.datetime :seen_at, null: false # la última vez que se abrió

      t.timestamps
    end
  end
end
