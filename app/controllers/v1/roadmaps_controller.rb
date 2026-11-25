# El roadmap como relato (MT-106, «v1 · 5 · Roadmap»): hacia dónde va el producto.
# Los hitos abiertos en orden son capítulos (Ahora, Siguiente, Después) con su
# objetivo, las capacidades que cambian sus historias y su avance; luego lo recién
# terminado y lo que ya está. Se reordenan hitos, no historias (eso es de MT-109).
#
# Las acciones usan el mismo modelo y los mismos eventos que `mt milestone`
# (reorder, create, close) y `mt` al mover historias de hito: una pantalla vieja
# no rompe nada porque cada una comprueba antes lo que vio quien la manda.
module V1
  class RoadmapsController < ApplicationController
    RECENT = 14.days

    def show
      render inertia: "Roadmap", props: { roadmap: InertiaRails.live(@project) { roadmap_props } }
    end

    # Arrastrar un capítulo: { milestone: 11, before: 10 } o { after: 12 }, con `seen`, el orden
    # de hitos abiertos que tenía la pantalla. Si ya no es el de ahora, no se toca nada.
    def reorder
      problem = nil
      @project.with_lock do
        open = @project.milestones.open.order(:position).to_a
        milestone = open.find { it.number == params[:milestone].to_i }
        relation = %i[before after].find { params[it].present? }
        target = relation && open.find { it.number == params[relation].to_i }
        problem = if milestone.nil? || target.nil?
          "Ese hito ya no está abierto. Recarga el roadmap."
        elsif Array(params[:seen]).map(&:to_i) != open.map(&:number)
          "El roadmap cambió mientras lo mirabas. Ya ves el orden de ahora: vuelve a moverlo."
        end
        # Junto a sí mismo: el orden no cambia.
        next if problem || target == milestone

        milestone.reorder!(position: { relation => target }, actor: Current.actor)
      end
      back(problem)
    end

    # «Nuevo hito»: al final, el siguiente (detrás del de ahora) o el primero.
    def create
      milestone = @project.with_lock do
        first = @project.milestones.open.order(:position).first
        created = @project.create_milestone!(params.permit(:title, :goal).to_h.with_defaults("title" => nil), actor: Current.actor)
        case params[:place]
        when "next" then created.reorder!(position: { after: first }, actor: Current.actor) if first
        when "first" then created.reorder!(position: { before: first }, actor: Current.actor) if first
        end
        created
      end
      redirect_to project_v1_roadmap_path(@project), notice: "#{milestone.code} creado."
    rescue ActiveRecord::RecordInvalid => e
      back(e.record.errors.full_messages.join(". "))
    end

    # «Cerrar un hito»: lo que queda abierto pasa al siguiente hito (al principio, en su
    # orden) o a la bandeja, y después se cierra. `open` son las historias abiertas que
    # vio quien cierra y `to`, el hito siguiente que vio: si algo cambió, no se cierra.
    def close
      problem = nil
      milestone = nil
      @project.with_lock do
        milestone = @project.milestones.find_by!(number: params[:number])
        pending = milestone.stories.where.not(state: :done).order(:position).to_a
        target = @project.milestones.open.where.not(id: milestone.id).find_by(number: params[:to]) if params[:destination] == "next"
        problem = if milestone.closed?
          "#{milestone.code} ya está cerrado."
        elsif Array(params[:open]).map(&:to_i).sort != pending.map(&:number).sort
          "Las historias de #{milestone.code} cambiaron mientras lo mirabas. Recarga y vuelve a cerrarlo."
        elsif pending.any? && params[:destination] == "next" && target.nil?
          "Ese hito ya no está abierto. Recarga el roadmap."
        elsif pending.any? && !%w[next ideas].include?(params[:destination])
          "Elige a dónde van las historias abiertas."
        end
        next if problem

        if target
          pending.reverse_each { it.reorder!(position: :first, milestone: target, actor: Current.actor) }
        else
          pending.each { it.reorder!(position: :last, milestone: nil, actor: Current.actor) }
        end
        milestone.close!(actor: Current.actor)
      end
      return back(problem) if problem

      redirect_to project_v1_roadmap_path(@project), notice: "#{milestone.code} cerrado."
    end

    private

    def back(problem)
      return redirect_to(project_v1_roadmap_path(@project)) unless problem

      redirect_to project_v1_roadmap_path(@project), inertia: { errors: { base: [ problem ] } }
    end

    def roadmap_props
      milestones = @project.milestones.order(:position).includes(:stories).to_a
      open, closed = milestones.partition { !it.closed? }
      closed = closed.sort_by { [ -it.closed_at.to_i, -it.number ] }
      recent = closed.select { it.closed_at >= RECENT.ago }
      recent = closed.first(1) if recent.empty?
      pages = @project.pages.documentation.index_by(&:slug)

      {
        vision: first_paragraph(brief_section("Visión")),
        chapters: open.each_with_index.map { |milestone, index| chapter_props(milestone, index, open, pages) },
        recent: recent.map { recent_props(it, pages) },
        recent_window: recent.any? { it.closed_at >= RECENT.ago },
        shipped: (closed - recent).map { { code: it.code, title: it.title, closed_at: it.closed_at.iso8601 } },
        ideas: { count: @project.ideas.count, url: project_path(@project) },
        reorder_url: project_v1_roadmap_order_path(@project),
        create_url: project_v1_milestones_path(@project),
        next_number: (@project.milestones.maximum(:number) || 0) + 1,
        copy: copy(open)
      }
    end

    def chapter_props(milestone, index, open, pages)
      stories = milestone.stories.to_a
      done = stories.count(&:done?)
      following = open[index + 1]
      {
        number: milestone.number,
        code: milestone.code,
        title: milestone.title,
        goal: milestone.goal.presence,
        capabilities: stories.flat_map(&:capabilities).uniq.filter_map { pages[it] }.map do |page|
          { title: page.title, icon: page.icon, url: project_v1_capability_path(@project, page.slug) }
        end,
        done: done,
        total: stories.size,
        next: stories.reject(&:done?).first&.then { { ref: it.reference, title: it.title, url: project_v1_story_path(@project, it.number) } },
        pending: stories.reject(&:done?).map { { number: it.number, ref: it.reference, title: it.title, human_state: it.human_state } },
        following: following && { number: following.number, code: following.code, title: following.title },
        close_url: project_v1_milestone_close_path(@project, milestone.number)
      }
    end

    def recent_props(milestone, pages)
      {
        code: milestone.code,
        title: milestone.title,
        goal: milestone.goal.presence,
        closed_at: milestone.closed_at.iso8601,
        stories: milestone.stories.map do |story|
          { ref: story.reference, title: story.title, icon: pages[story.capabilities.first]&.icon, url: project_v1_story_path(@project, story.number) }
        end
      }
    end

    def copy(open)
      lines = [ "Roadmap de #{@project.name}, en orden:" ]
      open.each_with_index do |milestone, index|
        done, total = milestone.stories.to_a.then { [ it.count(&:done?), it.size ] }
        lines << "#{index + 1}. #{milestone.code} · #{milestone.title} (#{done} de #{total} hechas)"
      end
      lines << "Sin hitos abiertos." if open.empty?
      lines << "Entero: `mt roadmap --project #{@project.key}`."
      lines.join("\n")
    end
  end
end
