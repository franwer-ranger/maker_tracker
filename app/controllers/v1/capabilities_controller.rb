# La página de una capacidad (MT-103, «v1 · 3 · Producto · Capacidad»): la
# documentación de MT-89 leída como página viva. Cabecera con su estado, la
# frase, «El recorrido» con sus capturas (MT-96), «Cómo funciona» y «¿Qué pasa
# si…?» sacados de su markdown (Page::Reading), y al lado cómo ha cambiado
# (MT-91), las decisiones que la rigen (MT-90) y sus relacionadas. En directo
# como la portada: cada evento del proyecto repinta `capability`.
module V1
  class CapabilitiesController < ApplicationController
    RELATED = 3
    HISTORY = 10

    before_action :set_page

    def show
      render inertia: "Capability", props: {
        capability: InertiaRails.live(@project) { capability_props }
      }
    end

    # El markdown de la página, el mismo que `mt doc <slug>`.
    def markdown
      render plain: Api::Markdown::Page.new(@page).to_s, content_type: "text/markdown"
    end

    private

    def set_page
      @page = @project.pages.documentation.find_by!(slug: params[:slug])
    end

    def capability_props
      page = @project.pages.find(@page.id)
      reading = Page::Reading.new(page.body)
      {
        slug: page.slug,
        title: page.title,
        icon: page.icon,
        area: page.area,
        kind: page.kind,
        empty: page.body.to_s.strip.empty?,
        status: status(page),
        **reading.to_h,
        screens: page.screenshots.each_with_index.map { |shot, index| { code: "C#{index + 1}", title: caption(shot.filename), src: Attachable.path(shot) } },
        changes: changes(page),
        decisions: Api::Markdown::Page.decisions_in_force(page).map { { reference: it.reference, title: it.title, url: project_brief_path(@project, anchor: it.reference) } },
        related: related(page).map { { slug: it.slug, title: it.title, icon: it.icon, url: project_v1_capability_path(@project, it.slug) } },
        copy: Api::Markdown::Page.new(page).to_s,
        edit: "Edita la página «#{page.title}» de la documentación de #{@project.name}: léela con `mt doc #{page.slug}` y guárdala con `mt doc edit #{page.slug} --file <f.md>`.",
        markdown_url: project_v1_capability_markdown_path(@project, page.slug)
      }
    end

    # «Al día · 23 nov, con PG-56»: la última historia que la cambió (o la última edición).
    # Si una historia Hecha que la cambia no la actualizó (MT-91), cuáles.
    def status(page)
      pending = @project.stories.documentation_pending.filter_map { |story, pages| story.reference if pages.include?(page) }
      change = page.story_changes.includes(:story).first
      edit = page.history.where(action: %w[page.created page.edited]).first
      latest = [ change, edit ].compact.max_by(&:occurred_at)
      { pending: pending, at: latest&.occurred_at&.iso8601, story: (change.story&.reference if change && latest == change) }
    end

    def changes(page)
      page.story_changes.includes(:actor, :story).limit(HISTORY).filter_map do |event|
        next unless event.story

        { at: event.occurred_at.iso8601, title: event.story.title, ref: event.story.reference, actor: event.actor.name,
          url: project_story_path(@project, event.story) }
      end
    end

    # Las que comparten alguna decisión vigente con ella y, después, las de su área.
    def related(page)
      pages = @project.pages.documentation.where.not(id: page.id)
      governed = pages.where(id: DecisionCapability.where(decision_id: page.decisions.in_force.select(:id)).select(:page_id)).ordered.to_a
      same_area = page.area ? pages.where(area: page.area).ordered.to_a : []
      (governed + same_area).uniq.first(RELATED)
    end

    # «c2-vas-a-buscarla.png» → «Vas a buscarla».
    def caption(filename)
      filename.base.sub(/\A(?:c?\d+)[\s._-]+/i, "").tr("_-", "  ").squish.upcase_first.presence || filename.to_s
    end
  end
end
