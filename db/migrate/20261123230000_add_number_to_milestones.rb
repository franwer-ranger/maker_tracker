# Códigos de hito estables (MT-61): cada hito tiene un número propio por
# proyecto, como las historias y las decisiones. Los que ya existen se quedan
# con el código que enseñan hoy (número = posición actual) y el contador del
# proyecto arranca en el mayor, para que no se reutilice ninguno.
class AddNumberToMilestones < ActiveRecord::Migration[8.1]
  def up
    add_column :projects, :last_milestone_number, :integer, default: 0, null: false
    add_column :milestones, :number, :integer

    execute "UPDATE milestones SET number = position"
    execute <<~SQL
      UPDATE projects SET last_milestone_number =
        COALESCE((SELECT MAX(number) FROM milestones WHERE milestones.project_id = projects.id), 0)
    SQL

    change_column_null :milestones, :number, false
    add_index :milestones, [ :project_id, :number ], unique: true
  end

  def down
    remove_index :milestones, [ :project_id, :number ]
    remove_column :milestones, :number
    remove_column :projects, :last_milestone_number
  end
end
