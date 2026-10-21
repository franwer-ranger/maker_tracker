# «Mientras no mirabas» (MT-31): lo que cambió desde la visita anterior de Fran,
# sin contar lo que hizo él. Es `Changes` (la misma consulta que la daily del
# agente) mirada por la UI: el resumen sale de los eventos, no de un LLM.
#
#   WhileAway.home(since: visita)   # la portada, por proyecto, y «Decidido por agentes»
#   WhileAway.story(story, since:)  # los eventos de una historia
class WhileAway
  # Lo que un agente decide o cambia del producto y Fran debería poder revisar
  # (MT-31): sus decisiones, el orden del roadmap, qué pasa a Lista y el brief.
  PRODUCT_ACTIONS = %w[decision.recorded story.reordered story.moved brief.edited
                       milestone.created milestone.edited milestone.closed milestone.reopened milestone.reordered].freeze
  SUMMARY_CLAUSES = 2

  # Un proyecto: sus cambios resumidos y por historia. `entries` solo trae
  # historias; los eventos sin historia (brief, hitos) van en `project_events`.
  Group = Data.define(:project, :events, :summaries, :stories, :project_events) do
    def count = events.size
  end
  StoryChange = Data.define(:story, :events)

  # Lo de la portada. `now` fija hasta dónde se lee, para que lo que se ve y lo que se marca como visto coincidan.
  class Home
    attr_reader :since

    def initialize(since:, now: Time.current, viewer: Actor.human)
      @since = since
      @now = now
      @viewer = viewer
    end

    def groups
      @groups ||= Project.order(:created_at).filter_map do |project|
        events = Changes.new(project, since: since, until_time: @now, except_actor: @viewer).events
        build_group(project, events) if events.any?
      end
    end

    # Decisiones y cambios de producto de agentes, del más antiguo al más reciente.
    def decided
      @decided ||= groups.flat_map(&:events).select { product_change?(it) }.sort_by { [ it.occurred_at, it.id ] }
    end

    def any? = groups.any?

    private

    def product_change?(event)
      return false unless event.actor.agent?

      PRODUCT_ACTIONS.include?(event.action) ||
        (event.action == "story.state_changed" && event.data["to"] == "ready" && !event.data["released"])
    end

    def build_group(project, events)
      with_story, project_events = events.partition(&:story)
      stories = with_story.group_by(&:story).map { |story, list| StoryChange.new(story, list) }
      Group.new(project: project, events: events, summaries: summaries(events), stories: stories, project_events: project_events)
    end

    # "claude cerró 3 historias y empezó MT-33": una frase por actor.
    def summaries(events)
      events.group_by(&:actor).map do |actor, list|
        clauses = clauses_for(list).first(SUMMARY_CLAUSES)
        clauses = [ "hizo #{list.size} #{list.one? ? 'cambio' : 'cambios'}" ] if clauses.empty?
        "#{actor.name} #{clauses.to_sentence(words_connector: ', ', two_words_connector: ' y ', last_word_connector: ' y ')}"
      end
    end

    def clauses_for(events)
      state_to = ->(event, to) { event.action == "story.state_changed" && event.data["to"] == to }
      of = ->(action) { events.select { it.action == action } }
      closed = events.select { state_to.(it, "done") }
      started = events.select { state_to.(it, "in_progress") }
      other = events.select { it.action == "story.state_changed" } - closed - started
      roadmap = events.select { it.action.match?(/\A(story\.(reordered|moved)|milestone\.|brief\.)/) }

      [
        closed.any? && "cerró #{stories_phrase(closed)}",
        started.any? && "empezó #{stories_phrase(started)}",
        of.("project.deployed").any? && deployed_phrase(of.("project.deployed")),
        count_phrase(of.("question.asked"), "preguntó en", "hizo", "preguntas"),
        decisions_phrase(of.("decision.recorded")),
        count_phrase(of.("comment.added"), "comentó en", "escribió", "comentarios"),
        of.("story.edited").any? && "editó #{stories_phrase(of.('story.edited'))}",
        other.any? && "movió #{stories_phrase(other)}",
        roadmap.any? && "tocó el roadmap o el brief"
      ].select(&:itself)
    end

    # "desplegó PG-30 y PG-32" (MT-46), o "desplegó 2 veces" si hay varias llamadas.
    def deployed_phrase(events)
      refs = events.flat_map { |event| Array(event.data["stories"]).map { "#{event.project.key}-#{it}" } }.uniq
      refs.any? ? "desplegó #{refs.to_sentence(words_connector: ', ', two_words_connector: ' y ', last_word_connector: ' y ')}" : "desplegó"
    end

    # "PG-48" o "3 historias".
    def stories_phrase(events)
      stories = events.filter_map(&:story).uniq
      stories.one? ? stories.first.reference : "#{stories.size} historias"
    end

    # "preguntó en PG-49" si es una; "hizo 3 preguntas" si son varias.
    def count_phrase(events, one, many, noun)
      return if events.empty?

      events.one? ? "#{one} #{stories_phrase(events)}" : "#{many} #{events.size} #{noun}"
    end

    def decisions_phrase(events)
      return if events.empty?

      events.one? ? "decidió D-#{events.first.data['number']}" : "tomó #{events.size} decisiones"
    end
  end

  def self.home(**args) = Home.new(**args)

  # Los eventos de una historia desde `since`, del más antiguo al más reciente.
  def self.story(story, since:, now: Time.current, viewer: Actor.human)
    Changes.new(story.project, since: since, until_time: now, except_actor: viewer).for_story(story).events
  end
end
