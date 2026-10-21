# El ciclo de un agente de desarrollo (#017): empezar, terminar y soltar una
# historia. Son Story#move_to! con datos extra en el evento. Repetir una
# operación que no cambia nada no es un error: ok y un summary que lo dice.
class Api::StoryWorkController < Api::BaseController
  # Reclama y pasa a En curso. Avisa si no estaba Lista, está bloqueada o no
  # tiene criterios.
  def start
    warnings = start_warnings
    changed = story.in_progress? && story.claimed_by.nil? ? story.claim!(actor: Current.actor) : story.move_to!(:in_progress, actor: Current.actor)
    summary = changed ? "#{story.reference} is in progress, claimed by #{Current.actor.name}." : "#{story.reference} was already in progress and is yours."
    breadcrumbs = if warnings.any?
      [ "mt show #{story.reference}", "mt release #{story.reference} --reason \"…\"" ]
    else
      [ "mt show #{story.reference}", "mt comment #{story.reference} \"…\"", "mt done #{story.reference} --commit <sha>" ]
    end
    render_ok(story_data, summary: summary, warnings: warnings, breadcrumbs: breadcrumbs)
  end

  # Pasa a Hecha con sus commits y su PR en el evento.
  def done
    ensure_not_claimed_by_other!
    commits = commits_param
    pr = params[:pr].presence
    warnings = []
    warnings << "it has no commits or PR: nobody will know where the code is. Use --commit <sha> or --pr <url>." if commits.empty? && pr.nil?

    changed = story.move_to!(:done, actor: Current.actor, data: { commits: commits, pr: pr })
    render_ok(story_data, summary: changed ? done_summary(commits, pr) : "#{story.reference} was already done.",
      warnings: changed ? warnings : [], breadcrumbs: [ "mt next" ])
  end

  # La devuelve a Lista y la libera, con el motivo en el evento.
  def release
    ensure_not_claimed_by_other!
    reason = params[:reason].presence
    raise Eventable::ReasonRequired if Current.actor.agent? && reason.nil?

    changed = story.in_progress? ? story.move_to!(:ready, actor: Current.actor, reason: reason) : story.release!(actor: Current.actor, reason: reason)
    summary = changed ? "#{story.reference} released: it is #{state_words(story.state)} again." : "#{story.reference} was not claimed by anyone."
    render_ok(story_data, summary: summary, breadcrumbs: [ "mt next", "mt comment #{story.reference} \"…\"" ])
  end

  private

  # `commits` llega como lista de shas o de `{sha, message}` (MT-44). Se guarda
  # el objeto si trae asunto y el sha a secas si no, y se lee con `Event#commits`.
  def commits_param
    Array(params[:commits]).filter_map do |item|
      sha, message = item.respond_to?(:to_unsafe_h) ? item.to_unsafe_h.values_at("sha", "message") : [ item, nil ]
      sha = sha.to_s.strip
      message = message.to_s.lines.first.to_s.strip.first(300)
      next if sha.blank?

      message.present? ? { sha: sha, message: message } : sha
    end
  end

  def story_data = { story: Api::Markdown::Formatting.story_data(story.reload) }

  def state_words(state) = Api::Markdown::Formatting.state_words(state)

  # "PG-51 was still being defined; it may lack context." y después, con "it".
  def start_warnings
    warnings = []
    warnings << "#{story.reference} was still an idea; it may lack context." if story.idea?
    warnings << "#{story.reference} was still being defined; it may lack context." if story.defining?
    warnings << "#{story.reference} was already done; it goes back to in progress." if story.done?
    blockers = project.stories.where(number: story.pending_blockers).order(:number)
    warnings << "it is blocked by #{Api::Markdown::Formatting.sentence(blockers.map { "#{it.reference} (#{state_words(it.state)})" })}." if blockers.any?
    questions = story.blocking_questions
    warnings << "it is waiting for #{Actor.human.name}: open #{questions.one? ? 'question' : 'questions'} #{Api::Markdown::Formatting.sentence(questions.map { "#{it.reference} from #{it.actor.name}" })}." if questions.any?
    warnings << "it has no acceptance criteria." unless story.criteria? || story.done?
    warnings
  end

  # "PG-49 done by claude, with 1 commit and PR #63."
  def done_summary(commits, pr)
    work = [ (Api::Markdown::Formatting.plural(commits.size, "commit") if commits.any?), (Api::Markdown::Formatting.pr_label(pr) if pr) ].compact
    "#{story.reference} done by #{Current.actor.name}#{", with #{work.join(' and ')}" if work.any?}."
  end

  def reason_required_error = reason_error("releasing", "mt release #{story.reference} --reason \"why you release it\"")

  # Terminar o soltar la de otro solo lo puede hacer Fran.
  def ensure_not_claimed_by_other!
    raise Story::ClaimedByOther, story if story.claimed_by && story.claimed_by != Current.actor && Current.actor.agent?
  end
end
