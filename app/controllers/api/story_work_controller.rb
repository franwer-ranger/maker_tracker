# El ciclo de un agente de desarrollo (#017): empezar, terminar y soltar una
# historia. Son Story#move_to! con datos extra en el evento. Repetir una
# operación que no cambia nada no es un error: ok y un summary que lo dice.
class Api::StoryWorkController < Api::BaseController
  # Reclama y pasa a En curso. Avisa si no estaba Lista o está bloqueada.
  def start
    warnings = []
    warnings << "#{story.reference} está en #{story.human_state}: puede que le falte contexto" if story.idea? || story.defining?
    warnings << "#{story.reference} ya estaba Hecha: vuelve a En curso" if story.done?
    blockers = pending_blockers
    warnings << "#{story.reference} está bloqueada por #{Api::Markdown::Formatting.sentence(blockers)}" if blockers.any?

    changed = story.in_progress? && story.claimed_by.nil? ? story.claim!(actor: Current.actor) : story.move_to!(:in_progress, actor: Current.actor)
    summary = changed ? "#{story.reference} en curso, reclamada por #{Current.actor.name}" : "#{story.reference} ya estaba en curso y es tuya"
    render_ok(story_data, summary: summary, warnings: warnings,
      breadcrumbs: [ "mt show #{story.reference}", "mt done #{story.reference} --commit <sha>", "mt comment #{story.reference} \"…\"" ])
  end

  # Pasa a Hecha con sus commits y su PR en el evento.
  def done
    ensure_not_claimed_by_other!
    commits = Array(params[:commits]).map(&:to_s).compact_blank
    pr = params[:pr].presence
    warnings = []
    warnings << "Sin commits ni PR: nadie sabrá dónde está el código. Usa --commit <sha> o --pr <url>" if commits.empty? && pr.nil?

    changed = story.move_to!(:done, actor: Current.actor, data: { commits: commits, pr: pr })
    summary = changed ? "#{story.reference} hecha por #{Current.actor.name}#{" · #{commits.size} #{commits.size == 1 ? 'commit' : 'commits'}" if commits.any?}#{' · PR' if pr}" : "#{story.reference} ya estaba hecha"
    render_ok(story_data, summary: summary, warnings: changed ? warnings : [], breadcrumbs: [ "mt next" ])
  end

  # La devuelve a Lista y la libera, con el motivo en el evento.
  def release
    ensure_not_claimed_by_other!
    reason = params[:reason].presence
    raise Eventable::ReasonRequired, "Un agente tiene que dar un motivo para soltar una historia" if Current.actor.agent? && reason.nil?

    changed = story.in_progress? ? story.move_to!(:ready, actor: Current.actor, reason: reason) : story.release!(actor: Current.actor, reason: reason)
    summary = changed ? "#{story.reference} liberada: vuelve a #{story.human_state}" : "#{story.reference} no la tenía nadie"
    render_ok(story_data, summary: summary, breadcrumbs: [ "mt next", "mt comment #{story.reference} \"…\"" ])
  end

  private

  def story_data = { story: Api::Markdown::Formatting.story_data(story.reload) }

  def pending_blockers
    pending = story.pending_blockers
    project.stories.where(number: pending).order(:number).map { "#{it.reference} (#{it.human_state.downcase})" }
  end

  # Terminar o soltar la de otro solo lo puede hacer Fran.
  def ensure_not_claimed_by_other!
    raise Story::ClaimedByOther, story if story.claimed_by && story.claimed_by != Current.actor && Current.actor.agent?
  end
end
