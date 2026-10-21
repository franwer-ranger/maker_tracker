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

  # La clave del proyecto en su cuadro (PG). `size` en px: 28 en la cabecera
  # del móvil (sin borde, 11px), 32 en la barra, 36 en la lista.
  def project_key_badge(project, size: 32)
    tag.span project.key, class: class_names(
      "flex shrink-0 items-center justify-center rounded-md bg-surface font-mono text-text",
      { 28 => "size-7 text-label", 32 => "size-8 text-xs", 36 => "size-9 text-xs" }.fetch(size),
      "shadow-[inset_0_0_0_1px_var(--color-border-strong)]": size != 28
    )
  end

  # A la derecha de un proyecto (5.0 y su hoja en el móvil): «2 en curso» con
  # el punto naranja o, si no hay nada en curso, «sin actividad · 2 d».
  def project_activity(project)
    in_progress = project.stories.in_progress.count
    if in_progress.positive?
      tag.span class: "flex shrink-0 items-center gap-1.5" do
        safe_join([ state_dot(:in_progress), tag.span("#{in_progress} en curso", class: "font-mono text-xs text-text-muted") ])
      end
    else
      last = project.last_activity_at
      tag.span "sin actividad#{" · #{short_time_ago(last)}" if last}", class: "shrink-0 font-mono text-xs text-text-subtle"
    end
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
