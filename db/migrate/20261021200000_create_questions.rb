# Preguntas de un agente con sus opciones (MT-29). Cuelgan de una historia y se
# consultan mucho ("abiertas en todos los proyectos"), por eso son una tabla y no
# un comentario con datos.
class CreateQuestions < ActiveRecord::Migration[8.1]
  def change
    create_table :questions do |t|
      t.references :story, null: false, foreign_key: true
      t.references :actor, null: false, foreign_key: true # quién pregunta
      t.string :title, null: false
      t.text :context, null: false, default: ""
      t.json :options, null: false, default: []
      t.integer :recommended # número de la opción recomendada (desde 1)
      t.boolean :reversible # nulo: sin indicar, no se asume irreversible
      t.boolean :blocking, null: false, default: true
      t.integer :answer # número de la opción elegida (desde 1)
      t.text :answer_note
      t.references :answered_by, foreign_key: { to_table: :actors }
      t.datetime :answered_at

      t.timestamps
    end
    add_index :questions, :answered_at
  end
end
