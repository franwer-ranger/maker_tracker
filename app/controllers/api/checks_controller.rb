# `mt check "…"` (MT-79): contrasta una propuesta con las decisiones, las
# historias y el brief. GET con `text` en la query o POST con él en el cuerpo
# (`mt check --file`, que puede ser largo); los dos leen, no escriben nada.
class Api::ChecksController < Api::BaseController
  def show
    text = params.require(:text).to_s
    check = ProposalCheck.new(project, text)
    if check.terms.empty?
      raise Api::Error.validation("nothing to search for: the proposal has no words that count.",
        hint: "describe what you want to do in a few words, like mt check \"avisar de historias casi listas\".")
    end

    view = Api::Markdown::Check.new(check)
    render_ok({ terms: check.terms.map(&:word), results: view.results, markdown: view.to_s },
      summary: view.results.empty? ? "Nothing matches in #{project.name}." : "#{Api::Markdown::Formatting.plural(view.results.size, 'result')} in #{project.name}.",
      breadcrumbs: view.breadcrumbs)
  end

  private

  # Un POST de check solo lee: para la presencia (MT-36) cuenta como «leyendo».
  # La respuesta ya está hecha cuando corre, así que tratarlo como GET no cambia nada más.
  def record_presence
    request.request_method = "GET" if request.post?
    super
  end
end
