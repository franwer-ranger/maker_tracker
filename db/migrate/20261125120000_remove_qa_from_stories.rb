# La QA sale de Maker Tracker (MT-98, D-97): probar lo construido es de Relay.
# Se pierde el estado de QA de cada historia (decisión de Fran: la copia de
# `bin/backup` lo conserva). Los eventos `qa.*` se quedan en el historial y
# `deployed_at` sigue: `mt deployed` marca lo desplegado.
#
# El índice se quita explícito, simétrico con `down`, que recrea la columna y
# su índice vacíos; los valores solo vuelven restaurando la copia.
class RemoveQaFromStories < ActiveRecord::Migration[8.1]
  def up
    remove_index :stories, :qa, name: "index_stories_on_qa"
    remove_column :stories, :qa
  end

  def down
    add_column :stories, :qa, :string
    add_index :stories, :qa, where: "qa IS NOT NULL"
  end
end
