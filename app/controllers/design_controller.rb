# Catálogo del sistema de diseño para revisarlo contra Paper. Solo existe en
# development (ver config/routes.rb).
class DesignController < ApplicationController
  def show
  end

  # Fila · Móvil (MT-45): las piezas del móvil a 390px, para verlas en /design
  # dentro de un iframe (así aplican sus media queries). Usa el primer proyecto.
  def mobile
    @project = Project.order(:created_at).first
    @milestone = @project&.current_milestone
    @context = { next_story: @project&.next_story, done_numbers: @project ? @project.stories.done.pluck(:number) : [] }
    @sheet = params[:hoja].present?
  end
end
