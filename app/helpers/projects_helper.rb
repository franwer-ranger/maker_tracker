module ProjectsHelper
  # "M2 · Publicar sin fricción"
  def milestone_label(milestone) = "#{milestone.code} · #{milestone.title}"

  # Tiempo corto para metadatos en mono: "5 min", "2 h", "3 d".
  def short_time_ago(time)
    seconds = Time.current - time
    if seconds < 1.hour then "#{[ (seconds / 60).floor, 1 ].max} min"
    elsif seconds < 1.day then "#{(seconds / 1.hour).floor} h"
    else "#{(seconds / 1.day).floor} d"
    end
  end

  # La clave del proyecto en su cuadro (PG). `size` en px: 32 en la barra, 36 en la lista.
  def project_key_badge(project, size: 32)
    tag.span project.key, class: class_names(
      "flex shrink-0 items-center justify-center rounded-md bg-surface font-mono text-xs text-text shadow-[inset_0_0_0_1px_var(--color-border-strong)]",
      { 32 => "size-8", 36 => "size-9" }.fetch(size)
    )
  end

  # Estado de un agente en la barra lateral: "en #48" si tiene una historia
  # En curso en el proyecto; si no, inactivo desde su último evento.
  def agent_status(project, agent)
    story = project.stories.in_progress.where(claimed_by: agent).ordered.first
    return actor(agent.name, active: true, detail: "en ##{story.number}") if story

    last = project.events.where(actor: agent).maximum(:occurred_at)
    actor(agent.name, detail: [ "inactivo", (short_time_ago(last) if last) ].compact.join(" · "))
  end
end
