# El ruido de los avisos (MT-47, D-66), por proyecto: cuándo salió el último
# (`last_pushed_at`, para la ventana de 10 minutos) y cuándo se avisó de que
# entraba en poco trabajo (`ready_low_notified_at`; nulo = rearmado).
class AddPushMarksToProjects < ActiveRecord::Migration[8.1]
  def change
    add_column :projects, :last_pushed_at, :datetime
    add_column :projects, :ready_low_notified_at, :datetime
  end
end
