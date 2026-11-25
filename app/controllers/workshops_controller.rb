# "/" (MT-97): la portada es el taller, del primer producto que tenga algo que
# definir (Workshop.default_project). Sin proyectos, a crear el primero.
class WorkshopsController < ApplicationController
  def show
    project = Workshop.default_project
    redirect_to project ? project_v1_workshop_path(project) : projects_path
  end
end
