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
          board: project_v1_story_list_path(@project),
          roadmap: project_v1_roadmap_path(@project),
          brief: project_brief_path(@project),
          decisions: project_v1_decisions_path(@project)
        },
        notice: flash[:notice],
        # El marco (MT-101): combo de producto, Taller, mapa de capacidades, agentes trabajando y usuario.
        # Perezoso: las recargas parciales (live props, índice del ⌘K) no lo piden y no se calcula.
        frame: -> { frame },
        # Quién trabaja y qué está editando ahora (MT-100): en directo en todas las pantallas.
        presence: InertiaRails.live(streams: Presence.live_streams(@project)) { presence_props },
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

    # Una sección del brief (`## Visión`) y su primer párrafo: la portada y el roadmap enseñan la visión.
    def brief_section(heading) = @project.brief[/^## #{Regexp.escape(heading)}\s*$(.*?)(?=^## |\z)/m, 1].to_s.strip

    # La visión entera (su primer párrafo); el énfasis `*…*` se queda para pintarlo en serif.
    def first_paragraph(text) = text.to_s.split(/\n\s*\n/).first.to_s.gsub(/\*\*|__|`/, "").squish.presence

    # El taller del producto actual: lo leen el marco y la portada, una vez por petición.
    def workshop = @workshop ||= Workshop.new(@project)

    def frame
      {
        products: Project.order(:name).map { { key: it.key, name: it.name, url: project_v1_cover_path(it) } },
        taller: workshop.count,
        capabilities: @project.pages.documentation.ordered.group_by { it.area.presence }.map do |area, pages|
          { area: area, items: pages.map { { slug: it.slug, title: it.title, url: project_v1_capability_path(@project, it.slug) } } }
        end,
        user: Current.actor&.name
      }
    end

    # La presencia (MT-100, Paper «09 · Presencia del agente»). `actors`: quién está activo, para la barra
    # lateral; `editing`: lo que se está editando ahora (EDITING desde su última escritura), con la clave del
    # elemento que lo pinta en pantalla (`data-presence`), su nombre para la pestaña, adónde lleva y cuántos
    # milisegundos le quedan: la página lo apaga sola aunque no le llegue la emisión del final.
    def presence_props
      now = Time.current
      {
        actors: Presence.active(project_id: @project.id).map { { name: it.actor_name, agent: it.agent?, label: presence_subject(it.target)&.dig(:label) } },
        editing: Presence.editing(project_id: @project.id).uniq(&:target).filter_map do |entry|
          subject = presence_subject(entry.target) or next
          { actor: entry.actor_name, agent: entry.agent?, **subject, left_ms: (entry.editing_left(now) * 1000).ceil }
        end
      }
    end

    # Qué es un destino de la presencia en la web: "MT-12", "MT M2", "brief", "page:slug", "decision:5".
    # Sin destino concreto ("page", "decision"), lo que se toca es la sección, sin elemento.
    def presence_subject(target)
      target = target.to_s
      if (number = presence_number(target, "#{@project.key}-"))
        return { key: "story:#{number}", label: target, url: project_v1_story_path(@project, number) }
      end
      if (number = presence_number(target, "#{@project.key} M"))
        return { key: "milestone:#{number}", label: "M#{number}", url: project_v1_roadmap_path(@project) }
      end

      case target
      when "brief"
        { key: "brief", label: "el brief", url: project_v1_cover_path(@project) }
      when /\Apage:(.+)\z/
        page = @project.pages.find_by(slug: $1)
        { key: "page:#{$1}", label: page&.title || $1, url: (project_v1_capability_path(@project, $1) if page && page.kind != "cover") }
      when "page"
        { key: nil, label: "la documentación", url: project_v1_cover_path(@project) }
      when /\Adecision:(\d+)\z/
        { key: "decision:#{$1}", label: "D-#{$1}", url: project_v1_decision_path(@project, $1) }
      when "decision"
        { key: nil, label: "las decisiones", url: project_v1_decisions_path(@project) }
      end
    end

    # El número tras el prefijo ("MT-" o "MT M") si el destino es exactamente prefijo + dígitos; sin regex
    # con la clave del proyecto dentro.
    def presence_number(target, prefix)
      return unless target.start_with?(prefix)

      number = target.delete_prefix(prefix)
      number if number.match?(/\A\d+\z/)
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
