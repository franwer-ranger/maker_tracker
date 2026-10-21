# El aviso «Un agente también está editando esta historia» del formulario de
# edición (MT-38). El formulario no se repinta en directo (se perdería lo
# escrito): solo este marco, que se vuelve a pedir con cada refresco del proyecto.
class Stories::AgentNoticesController < ApplicationController
  include ProjectScoped

  def show
    story = @project.stories.find_by!(number: params[:story_number])
    render partial: "agents/editing_notice_frame", locals: { story: story }
  end
end
