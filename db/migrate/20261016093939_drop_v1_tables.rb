# La v2 sustituye el modelo de la v1 (historia #002). No hay datos que conservar.
class DropV1Tables < ActiveRecord::Migration[8.1]
  def up
    # Primero las que tienen claves ajenas hacia las demás.
    %i[comments items sprints users projects].each do |table|
      drop_table table, if_exists: true
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
