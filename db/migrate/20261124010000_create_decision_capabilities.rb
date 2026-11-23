# Las capacidades que rige cada decisión (MT-90): una decisión puede regir
# varias páginas (capacidades o transversales) y una página tiene varias
# decisiones. Tabla nueva y vacía: no toca `decisions` (que solo se añaden) ni
# enlaza las que ya hay; eso lo hace el arranque de la documentación (MT-40).
class CreateDecisionCapabilities < ActiveRecord::Migration[8.1]
  def change
    create_table :decision_capabilities do |t|
      t.references :decision, null: false, foreign_key: true, index: false
      t.references :page, null: false, foreign_key: { on_delete: :cascade }
      t.timestamps
    end
    add_index :decision_capabilities, [ :decision_id, :page_id ], unique: true
  end
end
