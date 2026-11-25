# Prueba del stack v1 (MT-99, D-98): las páginas de Inertia + React de un proyecto,
# en /p/:slug/v1, conviviendo con las vistas de Hotwire. Se tira al acabar la prueba.
module V1
  class ApplicationController < ::InertiaController
    include ProjectScoped
    layout "inertia"

    inertia_share do
      {
        project: { key: @project.key, name: @project.name, slug: @project.slug },
        nav: {
          cover: project_v1_cover_path(@project),
          workshop: project_v1_workshop_path(@project),
          board: project_path(@project),
          roadmap: project_roadmap_path(@project),
          brief: project_brief_path(@project),
          decisions: project_v1_decisions_path(@project)
        },
        notice: flash[:notice],
        # El marco (MT-101): combo de producto, Taller, mapa de capacidades, agentes trabajando y usuario.
        # Perezoso: las recargas parciales (live props, índice del ⌘K) no lo piden y no se calcula.
        frame: -> { frame },
        # El ⌘K pide su índice al abrirse (recarga parcial), no con cada página.
        search: InertiaRails.optional { search_index }
      }
    end

    private

    # Una pregunta abierta como la pinta `OpenQuestion` (taller e historia), respondida en `answer_url`.
    def question_props(question, answer_url:)
      { id: question.id, title: question.title, context: question.context.presence, actor: question.actor.name,
        blocking: question.blocking?, recommended: question.recommended,
        options: question.options.each_with_index.map { |text, index| { value: (index + 1).to_s, label: text } },
        answer_url: answer_url }
    end

    # El taller del producto actual: lo leen el marco y la portada, una vez por petición.
    def workshop = @workshop ||= Workshop.new(@project)

    def frame
      {
        products: Project.order(:name).map { { key: it.key, name: it.name, url: project_v1_cover_path(it) } },
        taller: workshop.count,
        capabilities: @project.pages.documentation.ordered.group_by { it.area.presence }.map do |area, pages|
          { area: area, items: pages.map { { slug: it.slug, title: it.title, url: project_v1_capability_path(@project, it.slug) } } }
        end,
        agents: Presence.active(project_id: @project.id).map { { name: it.actor_name, target: it.target } },
        user: Current.actor&.name
      }
    end

    # Historias, capacidades y decisiones del proyecto, para buscar en el ⌘K.
    def search_index
      stories = @project.stories.includes(:milestone).order(number: :desc).map do |story|
        { value: "story:#{story.number}", ref: story.reference, title: story.title, state: story.state,
          meta: [ story.milestone&.code, Story.human_state(story.state) ].compact.join(" · "),
          url: project_v1_story_path(@project, story.number) }
      end
      capabilities = @project.pages.documentation.ordered.map do |page|
        { value: "page:#{page.slug}", ref: page.slug, title: page.title, meta: page.area.presence || (page.crosscutting? ? "Transversal" : ""),
          url: project_v1_capability_path(@project, page.slug) }
      end
      decisions = @project.decisions.includes(:superseded_by).reverse.map do |decision|
        { value: "decision:#{decision.number}", ref: decision.reference, title: decision.title,
          meta: decision.superseded_by ? "sustituida por #{decision.superseded_by.reference}" : "vigente",
          url: project_v1_decision_path(@project, decision.number) }
      end
      { stories: stories, capabilities: capabilities, decisions: decisions }
    end
  end
end
