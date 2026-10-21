# Avisos push (MT-47): una fila por dispositivo que activó los avisos. Sin
# sesiones ni login, cuelgan del actor humano. El navegador solo conoce el
# `endpoint`, así que es la clave para guardar (upsert) y para borrar.
class CreatePushSubscriptions < ActiveRecord::Migration[8.1]
  def change
    create_table :push_subscriptions do |t|
      t.references :actor, null: false, foreign_key: true
      t.text :endpoint, null: false
      t.string :p256dh, null: false
      t.string :auth, null: false
      t.string :user_agent
      t.datetime :last_sent_at
      t.timestamps
    end
    add_index :push_subscriptions, :endpoint, unique: true
  end
end
