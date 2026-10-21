# Lo que dice un evento en el historial de `mt show`, en inglés y sin el actor
# (va en su columna): "moved to ready", "edited body, mockup". La UI tiene su
# propia versión en castellano (StoriesHelper#event_sentence).
class Api::Markdown::EventSentence
  include Api::Markdown::Formatting

  # { milestone_id => "M2" }, para no buscar el hito evento a evento.
  def self.milestone_codes(project) = project.milestones.to_h { [ it.id, it.code ] }

  def initialize(event, milestone_codes)
    @event = event
    @data = event.data
    @milestone_codes = milestone_codes
  end

  def to_s
    [ sentence, (%("#{@event.reason}") if @event.reason) ].compact.join(": ")
  end

  private

  def sentence
    case @event.action
    when "story.created" then "created as #{state_words(@data['state'] || 'idea')}#{' (proposed in a daily)' if @data['daily']}"
    when "story.state_changed" then "moved to #{state_words(@data['to'])}#{work}#{' · QA pending' if @data['qa'] == 'pending'}"
    when "story.edited" then "edited #{Array(@data['fields']).join(', ')}"
    when "story.claimed" then "claimed it"
    when "story.released" then @data["from"] ? "released it from #{@data['from']}" : "released it"
    when "story.reordered" then "reordered it in its milestone"
    when "story.moved" then "moved it to #{milestone(@data.dig('to', 'milestone_id'))}"
    when "comment.added" then "commented"
    when "question.asked" then "asked: #{@data['title']}#{' (non-blocking)' if @data['blocking'] == false}"
    when "question.answered" then "answered #{@data['asked_by']}: #{@data['option'] ? "#{@data['option']} " : ''}#{@data['answer']}#{", recorded as D-#{@data['decision']}" if @data['decision']}"
    when "qa.passed" then "passed QA#{": #{@data['note']}" if @data['note']}"
    when "qa.failed" then "failed QA: #{@data['note']} (created #{@event.project.key}-#{@data['story']})"
    when "story.deployed" then "deployed (#{@data['sha'].to_s.first(7)})"
    when "project.deployed" then deployed_sentence
    when "decision.recorded" then "recorded D-#{@data['number']}"
    when "project.created" then "created the project"
    when "brief.edited" then "edited the brief"
    when "milestone.created" then "created milestone #{@data['title']}"
    when "milestone.edited" then "edited #{milestone_ref} (#{Array(@data['fields']).join(', ')})"
    when "milestone.closed" then "closed #{milestone_ref}"
    when "milestone.reopened" then "reopened #{milestone_ref}"
    when "milestone.reordered" then "reordered #{milestone_ref}"
    else @event.action
    end
  end

  # Una sola frase por llamada a `mt deployed` (MT-46): "deployed a1b2c3d: MT-30, MT-32 can be tested now".
  def deployed_sentence
    refs = Array(@data["stories"]).map { "#{@event.project.key}-#{it}" }
    "deployed #{@data['sha'].to_s.first(7)}#{": #{refs.join(', ')} can be tested now" if refs.any?}"
  end

  # Commits y PR al terminar: " (4f3e2a1 · Subject; 9b1c7d0, PR #63)".
  def work
    items = [ @event.commits.map(&:label).join("; ").presence ]
    items << pr_label(@data["pr"]) if @data["pr"].present?
    items.compact!
    " (#{items.join(', ')})" if items.any?
  end

  def milestone_ref = @milestone_codes.fetch(@data["milestone_id"], "a deleted milestone")

  def milestone(id) = id ? @milestone_codes.fetch(id, "a deleted milestone") : "the inbox"
end
