# `mt workshop` (MT-97): lo que la persona tiene que definir en el producto, lo
# mismo y en el mismo orden que el taller de la app. Para que el agente lo lleve
# a una entrevista corta.
class Api::WorkshopsController < Api::BaseController
  def show
    workshop = Api::Markdown::Workshop.new(Workshop.new(project))
    render_ok(workshop.data.merge(markdown: workshop.to_s), summary: workshop.summary, breadcrumbs: workshop.breadcrumbs)
  end
end
