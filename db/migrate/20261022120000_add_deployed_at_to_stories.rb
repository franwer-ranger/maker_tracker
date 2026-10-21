# La QA espera al despliegue (MT-46): cuándo `mt deployed` dio por desplegada una
# historia Hecha. Nulo al pasar a Hecha y al salir de ella, como `qa`. Un
# proyecto que nunca llama a `mt deployed` no la mira (ver Project#deploys?).
class AddDeployedAtToStories < ActiveRecord::Migration[8.1]
  def change
    add_column :stories, :deployed_at, :datetime
    # Project#deploys? y los scopes de QA preguntan por el evento project.deployed.
    add_index :events, %i[project_id action]
  end
end
