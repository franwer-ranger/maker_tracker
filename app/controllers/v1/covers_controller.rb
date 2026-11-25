# Portada del proyecto (MT-88, «v1 · 2 · Producto · Portada»): el brief hecho portada
# (D-92), sus capacidades y lo que está cambiando. En directo: cada evento del
# proyecto (también los de la CLI) emite al stream del proyecto y la página
# vuelve a pedir `cover` con una recarga parcial (Live props de Inertia).
module V1
  class CoversController < ApplicationController
    RECENT_EVENTS = 6

    def show
      render inertia: "Cover", props: {
        cover: InertiaRails.live(@project) { cover_props }
      }
    end

    private

    def cover_props
      in_progress = @project.stories.in_progress.includes(:claimed_by, :milestone).order(:updated_at).to_a
      changing = in_progress.flat_map(&:capabilities).to_set

      {
        vision: first_sentence(brief_section("Visión")),
        principles: bullets(brief_section("Principios")),
        out_of_scope: bullets(brief_section("Fuera de alcance")).presence || [ plain(brief_section("Fuera de alcance")) ].compact_blank,
        capabilities: capability_areas(changing),
        now: current_milestone_props,
        changing: in_progress.map { story_props(it) },
        recent: @project.events.recent_first.includes(:actor, :story).limit(RECENT_EVENTS).map { event_props(it) },
        agents: Presence.active(project_id: @project.id).map { { name: it.actor_name, writing: it.writing?, target: it.target } }
      }
    end

    def capability_areas(changing)
      @project.pages.documentation.ordered.group_by { it.area.presence || "Transversal" }.map do |area, pages|
        { area: area, items: pages.map { { slug: it.slug, title: it.title, summary: first_paragraph(it.body.to_s.sub(/\A##[^\n]*\n/, "")), changing: changing.include?(it.slug) } } }
      end
    end

    def current_milestone_props
      milestone = @project.current_milestone
      return unless milestone

      done, total = milestone.progress
      { code: milestone.code, title: milestone.title, goal: milestone.goal, status: milestone.status, done: done, total: total,
        edit_url: edit_project_v1_milestone_path(@project, milestone.number) }
    end

    def story_props(story)
      { ref: story.reference, title: story.title, actor: story.claimed_by&.name, milestone: story.milestone&.code,
        since: story.updated_at.iso8601, url: project_story_path(@project, story) }
    end

    def event_props(event)
      { id: event.id, actor: event.actor.name, agent: event.actor.agent?, text: helpers.session_event_text(event), at: event.occurred_at.iso8601 }
    end

    def brief_section(heading) = @project.brief[/^## #{Regexp.escape(heading)}\s*$(.*?)(?=^## |\z)/m, 1].to_s.strip

    def first_paragraph(text) = plain(text.split(/\n\s*\n/).first)

    # La visión en una frase (MT-88): hasta el primer punto.
    def first_sentence(text) = first_paragraph(text)&.then { it[/\A.+?[.!?](?=\s|\z)/] || it }

    def bullets(text) = text.lines.grep(/^\s*[-*] /).map { plain(it.sub(/^\s*[-*] /, "")) }

    # Sin el markdown de énfasis y código: la portada pinta texto.
    def plain(text) = text.to_s.gsub(/\*\*|__|`/, "").squish.presence
  end
end
