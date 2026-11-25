# Las historias de un producto (MT-109, «v1 · 8 · Historias»): la Lista por hito,
# en el orden del roadmap (los abiertos por su posición; después, los cerrados, del
# más reciente al más antiguo), y la bandeja de ideas al final. Cada fila dice qué
# capacidades cambia y por qué espera; buscar, Abiertas/Hechas/Todas y el combo de
# capacidad se filtran en la página. «Apuntar una idea» (N) la deja en la bandeja,
# sin hito, como `mt create`. Sustituye al tablero antiguo (`boards#show`).
module V1
  class StoryListsController < ApplicationController
    def show
      render inertia: "Stories", props: { stories: InertiaRails.live(@project) { list_props } }
    end

    # «Apuntar una idea»: título y, si hace falta, una línea más. Sin hito y en Idea.
    def create
      story = @project.create_story!({ title: params[:title].to_s.strip, body: params[:body].to_s.strip.presence, state: "idea", milestone: nil }.compact,
                                     actor: Current.actor)
      redirect_to project_v1_story_list_path(@project), notice: "#{story.reference} apuntada en la bandeja."
    rescue ActiveRecord::RecordInvalid => e
      redirect_to project_v1_story_list_path(@project), inertia: { errors: { base: [ e.record.errors.full_messages.join(". ") ] } }
    end

    private

    def list_props
      stories = @project.stories.includes(:questions, :claimed_by).to_a
      done_numbers = stories.select(&:done?).map(&:number)
      pages = @project.pages.documentation.ordered.to_a
      by_slug = pages.index_by(&:slug)
      milestones = @project.milestones.open.order(:position).to_a +
                   @project.milestones.closed.order(closed_at: :desc, number: :desc).to_a
      grouped = stories.group_by(&:milestone_id)

      {
        groups: milestones.map do |milestone|
          items = grouped.fetch(milestone.id, []).sort_by(&:position)
          { code: milestone.code, title: milestone.title, closed: milestone.closed?,
            done: items.count(&:done?), total: items.size,
            items: items.map { item_props(it, by_slug, done_numbers) } }
        end,
        # La bandeja no tiene orden: la última apuntada, arriba.
        ideas: grouped.fetch(nil, []).sort_by { -it.number }.map { item_props(it, by_slug, done_numbers) },
        capabilities: pages.map { { slug: it.slug, title: it.title, icon: it.icon } },
        open: stories.count { !it.done? },
        done: done_numbers.size,
        create_url: project_v1_story_list_path(@project),
        copy: "Las historias de #{@project.name}, por hito y en orden: `mt roadmap --project #{@project.key}`."
      }
    end

    def item_props(story, pages, done_numbers)
      { number: story.number, ref: story.reference, title: story.title, state: story.state,
        capabilities: story.capabilities.filter_map { pages[it] }.map { { slug: it.slug, title: it.title, icon: it.icon } },
        waiting: (waiting(story, done_numbers) unless story.done?),
        building: story.claimed_by && !story.done? ? { actor: story.claimed_by.name, agent: story.claimed_by.agent? } : nil,
        url: project_v1_story_path(@project, story.number) }
    end

    # Por qué espera: a una respuesta o al OK de quien mira («te toca a ti»), o a otras historias.
    def waiting(story, done_numbers)
      return { kind: "you" } if story.blocking_questions.any? || story.reviewable?

      pending = story.pending_blockers(done_numbers: done_numbers)
      return if pending.empty?

      { kind: "stories", refs: pending.map { "#{@project.key}-#{it}" } }
    end
  end
end
