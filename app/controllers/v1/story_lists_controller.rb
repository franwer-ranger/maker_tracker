# Las historias de un producto (MT-109, «v1 · 8 · Historias»): la Lista por hito,
# en el orden del roadmap (los abiertos por su posición; después, los cerrados, del
# más reciente al más antiguo), y la bandeja de ideas al final. Cada fila dice qué
# capacidades cambia y por qué espera; buscar, Abiertas/Hechas/Todas y el combo de
# capacidad se filtran en la página. «Apuntar una idea» (N) la deja en la bandeja,
# sin hito, como `mt create`. Sustituye al tablero antiguo (`boards#show`).
# El Tablero (MT-120) es la misma página por estado: arrastrar una tarjeta de
# columna es `mt move`, con sus mismas reglas.
module V1
  class StoryListsController < ApplicationController
    def show
      render inertia: "Stories", props: { stories: InertiaRails.live(@project) { list_props } }
    end

    # «Apuntar una idea»: título y, si hace falta, una línea más. Sin hito y en Idea.
    # El título es de una línea (lo imprimen `mt roadmap`, `mt next`, el ⌘K y las filas):
    # `squish` junta lo que llegue en varias líneas del Textarea (Shift+Enter o pegado).
    def create
      story = @project.create_story!({ title: params[:title].to_s.squish, body: params[:body].to_s.strip.presence, state: "idea" }.compact,
                                     actor: Current.actor)
      redirect_to project_v1_story_list_path(@project), notice: "#{story.reference} apuntada en la bandeja."
    rescue ActiveRecord::RecordInvalid => e
      redirect_to project_v1_story_list_path(@project), inertia: { errors: { base: [ e.record.errors.full_messages.join(". ") ] } }
    end

    # Las columnas del Tablero: «En curso» no es una, es Lista con la marca «en construcción».
    BOARD_STATES = %w[idea defining ready done].freeze

    # Arrastrar una tarjeta a otra columna del Tablero: como `mt move`, Story#move_to! decide. Pasar a Lista
    # sin cumplir la regla se hace y se avisa (el warning de `mt move`); si no se puede, se dice por qué.
    # Sacar de En curso a Idea o Definiendo la libera (como `mt move`), y el aviso dice a quién se le quitó.
    def move
      story = @project.stories.find_by!(number: params[:number])
      state = params[:state].to_s
      return back_to_list("Estado desconocido: #{state}.") unless BOARD_STATES.include?(state)

      holder = story.claimed_by if story.in_progress?
      changed = story.move_to!(state, actor: Current.actor)
      return back_to_list("#{story.reference} ya estaba en #{Story.human_state(state)}.") unless changed

      issues = state == "ready" ? story.readiness_issues : []
      notice = issues.empty? ? "#{story.reference} pasó a #{Story.human_state(state)}." : "#{story.reference} pasó a Lista, pero: #{issues.join(' ')}"
      notice += " Se liberó: la tenía #{holder.name}." if holder && story.claimed_by.nil?
      back_to_list(notice)
    rescue ActiveRecord::RecordInvalid => e
      back_to_list("#{story.reference} no se ha movido: #{e.record.errors.full_messages.join('. ')}.")
    end

    private

    def back_to_list(notice) = redirect_to(project_v1_story_list_path(@project), notice: notice)

    def list_props
      stories = @project.stories.includes(:questions, :claimed_by, :milestone).to_a
      done_numbers = stories.select(&:done?).map(&:number)
      pages = @project.pages.documentation.ordered.to_a
      by_slug = pages.index_by(&:slug)
      milestones = @project.milestones.open.order(:position).to_a +
                   @project.milestones.closed.order(closed_at: :desc, number: :desc).to_a
      grouped = stories.group_by(&:milestone_id)
      # Cuándo pasó cada una a Hecha (el Tablero enseña las últimas, con su fecha).
      closed_at = @project.events.where(action: "story.state_changed").where("json_extract(data, '$.to') = 'done'")
                          .group(:story_id).maximum(:occurred_at)

      {
        groups: milestones.map do |milestone|
          items = grouped.fetch(milestone.id, []).sort_by(&:position)
          { code: milestone.code, title: milestone.title, closed: milestone.closed?,
            done: items.count(&:done?), total: items.size,
            items: items.map { item_props(it, by_slug, done_numbers, closed_at) } }
        end,
        # La bandeja no tiene orden: la última apuntada, arriba.
        ideas: grouped.fetch(nil, []).sort_by { -it.number }.map { item_props(it, by_slug, done_numbers, closed_at) },
        capabilities: pages.map { { slug: it.slug, title: it.title, icon: it.icon } },
        open: stories.count { !it.done? },
        done: done_numbers.size,
        create_url: project_v1_story_list_path(@project),
        roadmap_url: project_v1_roadmap_path(@project),
        copy: "Las historias de #{@project.name}, por hito y en orden: `mt roadmap --project #{@project.key}`."
      }
    end

    def item_props(story, pages, done_numbers, closed_at)
      closed = (closed_at[story.id] || story.updated_at) if story.done?
      { number: story.number, ref: story.reference, title: story.title, state: story.state,
        capabilities: story.capabilities.filter_map { pages[it] }.map { { slug: it.slug, title: it.title, icon: it.icon } },
        waiting: (waiting(story, done_numbers) unless story.done?),
        building: story.claimed_by && !story.done? ? { actor: story.claimed_by.name, agent: story.claimed_by.agent? } : nil,
        milestone: story.milestone&.code,
        closed_on: closed && helpers.short_date(closed),
        closed_at: closed&.iso8601,
        url: project_v1_story_path(@project, story.number),
        move_url: project_v1_story_state_path(@project, story.number) }
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
