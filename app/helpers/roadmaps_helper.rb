module RoadmapsHelper
  # Resumen de un hito a la derecha de su fila (5.3) y su color:
  # "Hecho · 9/9 · 12 sep", "En curso · 4/12", "6 historias · 4 definiendo", "Solo ideas · 3".
  # En el móvil (5.3 · Móvil) cabe menos: "Hecho · 9/9" y "6 · 4 definiendo".
  def milestone_summary_tag(milestone)
    summary, color = milestone_summary(milestone)
    short = if summary.start_with?("Hecho") then summary.sub(/ · [^·]+\z/, "")
    elsif summary.include?(" historias ·") then summary.sub(" historias ·", " ·")
    end
    return tag.span(summary, class: color) unless short

    tag.span(class: color) { safe_join([ tag.span(summary, class: "max-md:hidden"), tag.span(short, class: "md:hidden") ]) }
  end

  def milestone_summary(milestone)
    stories = milestone.stories.to_a
    done = stories.count(&:done?)
    defining = stories.count(&:defining?)

    if milestone.closed?
      [ "Hecho · #{done}/#{stories.size} · #{short_date(milestone.closed_at)}", "text-state-done" ]
    elsif stories.empty?
      [ "Sin historias", "text-text-muted" ]
    elsif stories.all?(&:idea?)
      [ "Solo ideas · #{stories.size}", "text-text-muted" ]
    elsif stories.any? { it.in_progress? || it.done? }
      [ "En curso · #{done}/#{stories.size}", "text-text-muted" ]
    else
      [ "#{stories.size} historias · #{defining} definiendo", defining.positive? ? "text-state-defining" : "text-text-muted" ]
    end
  end
end
