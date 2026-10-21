# La daily del proyecto (MT-42). `mt daily` es un POST porque deja constancia
# de que el actor ha hecho su daily (su «última daily»); `mt daily idea`
# registra un evolutivo como idea, con tope por daily.
class Api::DailiesController < Api::BaseController
  # `mt daily [--since 2026-10-15]`: qué ha pasado desde la última daily de este
  # actor en este proyecto (o desde la fecha), en curso, bloqueado, lo que
  # espera a Fran y lo que toca.
  def create
    daily = Daily.new(project, Current.actor, since: since_param) # fija `now`: se lee hasta ahí y se registra ahí
    markdown = Api::Markdown::Daily.new(daily)
    text = markdown.to_s
    daily.hold!

    render_ok({ since: daily.since.localtime.iso8601, first: daily.first?, events: daily.changes.size,
                in_progress: daily.in_progress.map(&:reference), blocked: daily.blocked.map { |story, *| story.reference },
                waiting_for_human: daily.waiting_for_human.map { |story, _| story.reference },
                next: daily.next_story&.reference, markdown: text }.compact,
      summary: "Daily of #{Current.actor.name} in #{project.key}, #{markdown.window}.",
      breadcrumbs: [ "mt daily idea \"…\" --why \"…\"   (up to #{Daily::MAX_IDEAS} evolutionary ideas, after cross-checking with git log)",
                     *(daily.next_story ? [ "mt start #{daily.next_story.reference}" ] : []), "mt roadmap" ])
  end

  # `mt daily idea "Título" --why "…"`: una idea en la bandeja, nunca en el
  # roadmap. Como mucho MAX_IDEAS por daily.
  def idea
    daily = Daily.new(project, Current.actor)
    created = daily.propose_idea!(params.require(:title).to_s.strip, why: params[:why])
    count = daily.ideas.size
    render_ok({ story: Api::Markdown::Formatting.story_data(created), ideas: daily.ideas.map(&:reference), remaining: Daily::MAX_IDEAS - count },
      status: :created,
      summary: "#{created.reference} proposed as an idea in the inbox (#{count} of #{Daily::MAX_IDEAS} in this daily).",
      breadcrumbs: [ "mt show #{created.reference}", (count < Daily::MAX_IDEAS ? "mt daily idea \"…\" --why \"…\"" : "mt roadmap") ])
  rescue Daily::NotHeld
    raise Api::Error.validation("you haven't done your daily in #{project.key} yet.", hint: "run mt daily first: ideas are proposed after reading it.")
  rescue Daily::IdeaLimit
    raise Api::Error.validation("a daily proposes at most #{Daily::MAX_IDEAS} ideas and you have already created them: #{Daily.new(project, Current.actor).ideas.map(&:reference).join(', ')}.",
      hint: "choose the best ones; the rest can wait for the next daily. Edit one with mt edit if you need to change it.")
  end

  private

  # --since: «2026-10-15» o «2026-10-15 22:40», en la hora del servidor.
  def since_param
    value = params[:since].presence
    return unless value

    Time.zone.parse(value.to_s) || raise(ArgumentError)
  rescue ArgumentError
    raise Api::Error.validation("since must be a date like 2026-10-15 or 2026-10-15 22:40, not #{value}.", hint: "mt daily --since 2026-10-15")
  end
end
