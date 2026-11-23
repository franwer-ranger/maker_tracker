# `mt check "…"` (MT-79, docs/CLI.md): los candidatos de ProposalCheck, cada
# uno con su referencia, quién y cuándo, el porqué o un extracto y qué palabras
# coinciden. Para que el agente juzgue y se lo cuente a su persona.
class Api::Markdown::Check
  include Api::Markdown::Formatting

  EXCERPT_LENGTH = 240

  def initialize(check)
    @check = check
    @project = check.project
  end

  def results = @results ||= @check.results.map { result_data(it) }

  def to_s
    query = @check.text.squish.truncate(80, omission: "…")
    lines = [ "# Check · #{@project.name} · #{@project.key}", "", "Proposal: #{query}", "Searched for: #{@check.terms.map(&:word).join(', ')}", "" ]
    if results.empty?
      lines << "Nothing in the decisions, the stories or the brief matches. Try other words: the ones the product uses " \
               "(the titles in mt roadmap, the glossary in the brief), synonyms, or fewer and more specific words."
    else
      lines << "#{plural(results.size, 'result')}, most relevant first. They are candidates: whether the proposal clashes with them is for you to judge."
      lines << "None of them matches more than half of the searched words: the proposal may be new. Read them before saying so." if weak?
      results.each { lines.push("", *item(it)) }
    end
    lines.join("\n") + "\n"
  end

  # Lo que tiene sentido después, según lo que ha salido: leer la historia,
  # sustituir la decisión (si está entre las primeras), comentar o crear.
  def breadcrumbs
    return [ "mt check \"<other words>\"", "mt decisions", "mt roadmap", "mt create \"…\"" ] if results.empty?

    story = results.find { it[:type] == "story" }
    return [ "mt create \"…\"", ("mt show #{story[:reference]}" if story) ].compact if weak?

    decision = results.first(3).find { it[:type] == "decision" && it[:state] == "in_force" }
    open_story = results.find { it[:type] == "story" && it[:state] != "done" }
    [ ("mt show #{story[:reference]}" if story),
      ("mt decide \"…\" --why \"…\" --supersedes #{decision[:reference]}" if decision),
      ("mt comment #{open_story[:reference]} \"…\"" if open_story),
      "mt create \"…\"" ].compact
  end

  # Ningún candidato coincide en más de la mitad de las palabras: puede ser nueva.
  def weak? = results.none? { it[:matches].size * 2 > @check.terms.size }

  private

  def result_data(result)
    doc = result.document
    data = case doc.kind
    when :decision then decision_result(doc.record)
    when :story then story_result(doc.record, result.excerpt)
    else brief_result(doc)
    end
    data.merge(matches: result.matches, matched_in: result.fields.map { field_name(doc.kind, it) }, score: result.score.round(3))
  end

  def decision_result(decision)
    newer = decision.superseded_by
    { type: "decision", reference: decision.reference, title: decision.title, actor: decision.actor.name, date: date(decision.created_at),
      state: newer ? "superseded" : "in_force", superseded_by: newer&.reference, superseded_by_title: newer&.title,
      story: decision.story&.reference, why: excerpt(decision.body) }.compact
  end

  # Quién y cuándo: quien la cerró si está hecha; si no, quien la creó.
  def story_result(story, snippet)
    event = story_events[story.id]&.then { |events| (story.done? && events[:done]) || events[:created] }
    { type: "story", reference: story.reference, title: story.title, state: story.state,
      milestone: story.milestone&.code, milestone_title: story.milestone&.title,
      actor: event&.actor&.name, date: event && date(event.occurred_at), excerpt: excerpt(snippet) }.compact
  end

  def brief_result(doc)
    actor, at = @project.last_editor
    { type: "brief", section: doc.section, actor: actor&.name, date: at && date(at), excerpt: excerpt(doc.body) }.compact
  end

  # Los eventos de creación y cierre de las historias que han salido, de una vez.
  def story_events
    @story_events ||= begin
      ids = @check.results.filter_map { it.document.record.id if it.document.kind == :story }
      Event.where(story_id: ids, action: %w[story.created story.state_changed]).includes(:actor).order(:occurred_at, :id)
        .group_by(&:story_id).transform_values do |events|
          { created: events.find { it.action == "story.created" }, done: events.reverse.find { it.data["to"] == "done" } }
        end
    end
  end

  def field_name(kind, field)
    case field
    when :title then kind == :brief ? "section" : "title"
    when :body then { decision: "why", story: "body", brief: "text" }.fetch(kind)
    else "comments"
    end
  end

  def excerpt(text) = text.to_s.squish.truncate(EXCERPT_LENGTH, omission: "…").presence

  # D-80 · claude · 2026-11-09 · decision in force
  #   Una historia está en Definiendo o Lista: …
  #   Why: Fran: lo que le falta a una historia …
  #   Matches: avisar, casi, listas (title, why)
  def item(data)
    head, title, text = case data[:type]
    when "decision"
      state = data[:superseded_by] ? "decision superseded by #{data[:superseded_by]} (#{data[:superseded_by_title]})" : "decision in force"
      [ [ data[:reference], data[:actor], data[:date], state, data[:story] ], data[:title], data[:why] && "Why: #{data[:why]}" ]
    when "story"
      milestone = data[:milestone] ? "#{data[:milestone]} · #{data[:milestone_title]}" : "inbox"
      [ [ data[:reference], data[:actor], data[:date], "story #{state_words(data[:state])}", milestone ], data[:title], data[:excerpt] && "Excerpt: #{data[:excerpt]}" ]
    else
      [ [ "Brief", data[:section], data[:actor], data[:date] ], nil, data[:excerpt] ]
    end
    [ head.compact.join(" · "), title, text, "Matches: #{data[:matches].join(', ')} (#{data[:matched_in].join(', ')})" ].compact.map.with_index { |line, i| i.zero? ? line : "  #{line}" }
  end
end
