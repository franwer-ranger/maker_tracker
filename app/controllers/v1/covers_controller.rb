# Portada del producto (MT-102, «v1 · 2 · Producto · Portada»): el brief hecho
# portada (D-92) con el estado de la documentación, sus capturas (MT-96), el mapa
# de capacidades por área, principios, lo que no es, el hito de ahora y «Qué está
# cambiando» (las historias abiertas que declaran capacidades, MT-91). Todo sale
# de la documentación y de las historias. En directo: cada evento del proyecto
# (también los de la CLI) emite al stream del proyecto y la página vuelve a pedir
# `cover` con una recarga parcial (Live props de Inertia).
module V1
  class CoversController < ApplicationController
    SCREENSHOTS = 3
    CHANGING = 5
    OPEN_STATES = %w[in_progress ready defining].freeze
    DOC_EDITS = %w[brief.edited page.created page.edited].freeze

    def show
      render inertia: "Cover", props: {
        cover: InertiaRails.live(@project) { cover_props }
      }
    end

    private

    def cover_props
      pages = @project.pages.documentation.ordered.to_a
      vision = brief_section("Visión")
      # Lo que un agente está tocando ahora: las historias que tiene abiertas en la API (Presence).
      touched = Presence.active(project_id: @project.id).filter_map { [ it.target, it.actor_name ] if it.target }.to_h
      changing = changing_stories
      touching_now = changing.select { touched[it.reference] }.flat_map(&:capabilities).to_set
      open_capabilities = changing.flat_map(&:capabilities).to_set
      titles = pages.index_by(&:slug).transform_values(&:title)

      {
        empty: vision.blank? && pages.empty?,
        logo: (rails_blob_path(@project.logo, only_path: true) if @project.logo.attached?),
        status: documentation_status,
        vision: first_paragraph(vision),
        screenshots: (@project.cover&.screenshots || []).first(SCREENSHOTS).map { { url: Attachable.path(it), name: it.filename.to_s } },
        capabilities: pages.group_by { it.area.presence || "Transversal" }.map do |area, items|
          { area: area, items: items.map { capability_props(it, now: touching_now, open: open_capabilities) } }
        end,
        capability_count: pages.size,
        principles: bullets(brief_section("Principios")),
        out_of_scope: out_of_scope,
        now: current_milestone_props,
        changing: changing.first(CHANGING).map { story_props(it, titles, touched[it.reference]) },
        context: Api::Markdown::Context.new(@project).to_s,
        brief_url: edit_project_brief_path(@project),
        markdown_url: project_brief_path(@project)
      }
    end

    # «Al día · hace 2 días · por claude»: la última edición de la documentación, y si hay
    # historias Hechas sin actualizar sus páginas (MT-91), cuántas.
    def documentation_status
      event = @project.events.where(action: DOC_EDITS).includes(:actor).recent_first.first
      { pending: Api::Markdown::Context.new(@project).documentation_pending.size, at: event&.occurred_at&.iso8601, by: event&.actor&.name }
    end

    # Las historias abiertas que cambian alguna capacidad: primero las En curso, luego por estado y orden.
    def changing_stories
      @project.stories.where(state: OPEN_STATES).includes(:claimed_by).to_a
        .select { it.capabilities.any? }
        .sort_by { [ OPEN_STATES.index(it.state), it.position.to_i ] }
    end

    def capability_props(page, now:, open:)
      { slug: page.slug, title: page.title, icon: page.icon, url: project_v1_capability_path(@project, page.slug), summary: plain(first_paragraph(page.body.to_s.sub(/\A##[^\n]*\n/, ""))),
        changing: now.include?(page.slug) ? "now" : (open.include?(page.slug) ? "open" : nil) }
    end

    def current_milestone_props
      milestone = @project.current_milestone
      return unless milestone

      done, total = milestone.progress
      { code: milestone.code, title: milestone.title, done: done, total: total, next: @project.next_story&.reference }
    end

    def story_props(story, titles, agent)
      { ref: story.reference, title: story.title, capabilities: story.capabilities.filter_map { titles[it] },
        agent: agent, url: project_v1_story_path(@project, story.number) }
    end

    def out_of_scope
      section = brief_section("Fuera de alcance")
      bullets(section).presence || section.split(/(?<=\.)\s+/).filter_map { plain(it)&.delete_suffix(".") }
    end

    def brief_section(heading) = @project.brief[/^## #{Regexp.escape(heading)}\s*$(.*?)(?=^## |\z)/m, 1].to_s.strip

    # La visión entera (su primer párrafo); el énfasis `*…*` se queda para pintarlo en serif.
    def first_paragraph(text) = text.to_s.split(/\n\s*\n/).first.to_s.gsub(/\*\*|__|`/, "").squish.presence

    def bullets(text) = text.lines.grep(/^\s*[-*] /).map { plain(it.sub(/^\s*[-*] /, "")) }.compact

    # Sin el markdown de énfasis y código: la portada pinta texto.
    def plain(text) = text.to_s.gsub(/\*\*|__|`|\*/, "").squish.presence
  end
end
