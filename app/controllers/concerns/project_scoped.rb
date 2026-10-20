# Controladores de dentro de un proyecto: cargan @project por su slug y usan
# el layout con la barra lateral.
module ProjectScoped
  extend ActiveSupport::Concern

  included do
    layout "project"
    before_action :set_project
  end

  private

  def set_project
    @project = Project.find_by!(slug: params[:project_slug])
    session[:project_slug] = @project.slug # la barra de Actividad enseña el último proyecto visitado
  end
end
