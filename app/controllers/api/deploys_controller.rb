# La QA espera al despliegue (MT-46, D-62..D-64). `mt deployed` lee los
# candidatos (GET), decide con git cuáles contiene el sha desplegado y se lo
# dice al servidor (POST), que no necesita el repo. Cualquier actor con token
# puede llamarlo: avisar de un despliegue no es probar la QA.
class Api::DeploysController < Api::BaseController
  Formatting = Api::Markdown::Formatting
  MAX_STORIES = 500

  # Las historias Hechas con QA pendiente y sin desplegar, con los commits y el
  # PR de su evento de Hecha. `active`: si el proyecto ya espera al despliegue.
  def index
    candidates = project.deploy_candidates
    summary = "#{candidates.size} #{candidates.one? ? 'story' : 'stories'} done and not deployed yet in #{project.key}."
    render_ok({ active: project.deploys?, stories: candidates.map { candidate_data(*it) }, markdown: list_markdown(summary, candidates) },
      summary: summary, breadcrumbs: [ "mt deployed" ])
  end

  # `{ sha, stories: [30, 32] }`: marca esas historias como desplegadas.
  def create
    sha = params.require(:sha).to_s.strip
    raise Api::Error.validation("sha must be a git commit sha.", hint: "mt deployed [<sha>] sends it for you.") unless sha.match?(/\A\h{4,64}\z/)

    list = Array(params[:stories])
    raise Api::Error.validation("stories can have at most #{MAX_STORIES} numbers.") if list.size > MAX_STORIES

    numbers = list.map { Integer(it.to_s.delete_prefix("#").delete_prefix("#{project.key}-"), 10, exception: false) }
    raise Api::Error.validation("stories must be a list of story numbers.", hint: "for example { \"sha\": \"a1b2c3d\", \"stories\": [30, 32] }.") if numbers.any?(&:nil?)

    warnings = Array(params[:warnings]).first(MAX_STORIES).map { it.to_s.truncate(300) }
    marked = project.deploy!(sha: sha, numbers: numbers, actor: Current.actor, warnings: warnings)
    refs = marked.map(&:reference)
    summary = refs.any? ? "Deployed #{sha.first(7)}: #{refs.to_sentence} can be tested now." : "Deployed #{sha.first(7)}: no story was waiting for it."
    render_ok({ sha: sha, marked: refs, stories: marked.map { Formatting.story_data(it) } }, status: :created, summary: summary, breadcrumbs: [ "mt qa" ])
  end

  private

  def candidate_data(story, event)
    { reference: story.reference, number: story.number, title: story.title, done_at: event&.occurred_at&.iso8601,
      commits: event ? event.commits.map(&:sha) : [], pr: event&.data&.dig("pr").presence }.compact
  end

  # PG-30  Title  done 2026-10-20 18:40  2 commits, PR https://…
  def list_markdown(summary, candidates)
    return "#{summary}\n" if candidates.empty?

    rows = candidates.map do |story, event|
      work = [ ("#{event.commits.size} #{event.commits.one? ? 'commit' : 'commits'}" if event&.commits&.any?), (event.data["pr"].presence && "PR #{event.data['pr']}") ].compact
      [ story.reference, story.title, ("done #{Formatting.datetime(event.occurred_at)}" if event), work.join(", ").presence || "nothing to check" ]
    end
    "#{summary}\n\n#{Formatting.table(rows, min: [ 0, Formatting::TITLE_WIDTH ]).join("\n")}\n"
  end
end
