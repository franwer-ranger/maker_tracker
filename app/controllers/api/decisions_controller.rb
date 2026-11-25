# `mt decisions`: todas, de la más reciente a la más antigua. Con
# `--capability tablero`, solo las que rigen esa página (MT-90).
class Api::DecisionsController < Api::BaseController
  TITLE_MIN = 47 # columna del título (docs/CLI.md → mt decisions)

  def index
    page = find_page(params[:capability]) if params[:capability].present?
    decisions = (page&.decisions || project.decisions).reorder(number: :desc).includes(:actor, :story, :supersedes, :superseded_by, :capabilities).to_a
    data = decisions.map do |decision|
      { reference: decision.reference, title: decision.title, body: decision.body, actor: decision.actor.name,
        date: Api::Markdown::Formatting.date(decision.created_at), story: decision.story&.reference,
        supersedes: decision.supersedes&.reference, superseded_by: decision.superseded_by&.reference,
        capabilities: decision.capabilities.map(&:slug).sort.presence }.compact
    end
    empty = page ? "No decisions govern #{page.slug} yet." : "No decisions yet."
    render_ok({ decisions: data, markdown: markdown(data, empty:) },
      summary: "#{Api::Markdown::Formatting.plural(data.size, 'decision')} #{page ? "governing #{page.slug}" : "in #{project.name}"}.")
  end

  # `mt decide "…" --why "…" [--story PG-49] [--supersedes D-9] [--capability tablero]…`.
  # Solo se añaden. Rige las capacidades que se le dan y hereda las de su
  # historia y las de la que sustituye (Project#record_decision!).
  def create
    story = find_story(params[:story]) if params[:story].present?
    supersedes = find_decision(params[:supersedes]) if params[:supersedes].present?
    pages = capability_slugs.map { find_page(it) }
    decision = project.record_decision!({ title: params.require(:title), body: params[:body].to_s, story: story, supersedes: supersedes },
      actor: Current.actor, capabilities: pages)
    slugs = decision.capabilities.map(&:slug).sort
    warnings = decision.body.blank? ? [ "it has no why: add --why next time, it's what gets read later." ] : []
    render_ok({ decision: { reference: decision.reference, title: decision.title, story: story&.reference, supersedes: supersedes&.reference,
                            capabilities: slugs.presence }.compact },
      status: :created, warnings: warnings,
      summary: "#{decision.reference} recorded by #{Current.actor.name}#{", superseding #{supersedes.reference}" if supersedes}" \
               "#{", governing #{Api::Markdown::Formatting.sentence(slugs)}" if slugs.any?}.",
      breadcrumbs: [ "mt decisions", *slugs.first(1).map { "mt doc #{it}" } ])
  end

  # `mt decision link D-45 D-52 --capability revelarlo…` (MT-115): decisiones
  # que ya existen pasan a regir esas páginas. Lo ya enlazado no se duplica.
  def link
    decisions, pages = link_targets
    added = project.link_decisions!(decisions, pages, actor: Current.actor)
    superseded = decisions.select(&:superseded_by)
    links_response(decisions, pages, added,
      done: verb(decisions, "now govern"), none: "already governed", unchanged: "already there",
      warnings: superseded.map { "#{it.reference} is superseded by #{it.superseded_by.reference}: it does not show under Decisions in force." })
  end

  # `mt decision unlink D-52 --capability revelarlo`: les quita esas páginas.
  def unlink
    decisions, pages = link_targets
    removed = project.unlink_decisions!(decisions, pages, actor: Current.actor)
    links_response(decisions, pages, removed, done: verb(decisions, "no longer govern"), none: "did not govern", unchanged: "not there")
  end

  private

  # Las decisiones (D-45 o 45) y las páginas de link y unlink, sin repetir.
  def link_targets
    references = Array(params[:decisions]).flat_map { it.to_s.split(",") }.map(&:strip).compact_blank
    raise Api::Error.validation("name at least one decision (D-52).", hint: "see them with mt decisions.") if references.empty?

    slugs = capability_slugs
    raise Api::Error.validation("name at least one page with --capability.", hint: "see them with mt doc.") if slugs.empty?

    [ references.map { find_decision(it) }.uniq.sort_by(&:number), slugs.map { find_page(it) }.uniq.sort_by(&:slug) ]
  end

  # "D-45 and D-52 now govern revelarlo (1 link was already there)." si
  # cambió algún enlace; "D-52 already governed revelarlo: nothing changed." si ninguno.
  def links_response(decisions, pages, changed, done:, none:, unchanged:, warnings: [])
    refs = Api::Markdown::Formatting.sentence(decisions.map(&:reference))
    slugs = Api::Markdown::Formatting.sentence(pages.map(&:slug))
    same = decisions.size * pages.size - changed.size
    summary = if changed.empty?
      "#{refs} #{none} #{slugs}: nothing changed."
    else
      "#{refs} #{done} #{slugs}#{" (#{Api::Markdown::Formatting.plural(same, 'link')} #{same == 1 ? 'was' : 'were'} #{unchanged})" if same.positive?}."
    end
    render_ok({ decisions: decisions.map(&:reference), capabilities: pages.map(&:slug),
                changed: changed.map { |decision, page| { decision: decision.reference, capability: page.slug } } },
      summary: summary, warnings: warnings,
      breadcrumbs: [ "mt doc #{pages.first.slug}", "mt decisions --capability #{pages.first.slug}" ])
  end

  # "D-52 now governs", "D-45 and D-52 now govern".
  def verb(decisions, plural) = decisions.one? ? plural.sub(/govern\z/, "governs") : plural

  # `capabilities` como lista o como texto ("tablero, editor"). Un
  # `--capability ""` es un error, no una decisión sin capacidades.
  def capability_slugs
    if Array(params[:capabilities]).any? { it.to_s.split(",").map(&:strip).compact_blank.empty? }
      raise Api::Error.validation("--capability needs a page slug.", hint: "see them with mt doc.")
    end

    Array(params[:capabilities]).flat_map { it.to_s.split(",") }.map { it.strip.downcase }.compact_blank.uniq
  end

  def find_page(slug)
    page = project.pages.find_by(slug: slug.to_s.strip.downcase) ||
      raise(Api::Error.not_found("no page #{slug} in #{project.key}.", hint: "see them with mt doc."))
    return page unless page.cover?

    raise Api::Error.validation("the cover is not a capability: it is the brief.", hint: "name a capability or a cross-cutting page (mt doc).")
  end

  def find_decision(reference)
    number = Integer(reference.to_s.sub(/\AD-/i, ""), exception: false)
    project.decisions.find_by(number: number) ||
      raise(Api::Error.not_found("decision #{reference} does not exist.", hint: "see them with mt decisions."))
  end

  # D-14  PDFs con Prawn, sin servicios externos           claude  2026-10-16  PG-48
  #       Why: autoalojado y sin coste por documento.
  def markdown(data, empty:)
    return "#{empty}\n" if data.empty?

    rows = data.map do |d|
      tags = [ d[:story], ("supersedes #{d[:supersedes]}" if d[:supersedes]), ("superseded by #{d[:superseded_by]}" if d[:superseded_by]) ].compact
      [ d[:reference], d[:title], d[:actor], d[:date], tags.join("  ") ]
    end
    lines = Api::Markdown::Formatting.table(rows, min: [ 0, TITLE_MIN, "claude".length ])
    indent = " " * (rows.map { it.first.length }.max + 2)
    items = lines.zip(data).map do |line, d|
      why = d[:body].to_s.strip
      why.present? ? "#{line}\n#{indent}Why: #{why.gsub(/\n(?=.)/, "\n#{indent}")}" : line
    end
    "#{items.join("\n")}\n"
  end
end
