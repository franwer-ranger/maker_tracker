module RoadmapsHelper
  # Resumen de un hito a la derecha de su fila (5.3) y su color:
  # "Hecho · 9/9 · 12 sep", "En curso · 4/12", "6 historias · 4 definiendo", "Solo ideas · 3".
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
