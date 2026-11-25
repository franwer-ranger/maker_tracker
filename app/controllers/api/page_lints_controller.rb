# `mt doc lint <slug>` y `mt doc lint --all` (MT-123): cómo se leerá una
# página en la web (Page::Lint, con el mismo Page::Reading), sin abrirla.
# Solo lee. `data.errors` es cuántos errores hay: con alguno, mt sale con 1.
class Api::PageLintsController < Api::BaseController
  def index
    lints = project.pages.documentation.ordered.map { Page::Lint.new(it) }
    render_lints(lints, summary: all_summary(lints))
  end

  def show
    page = project.pages.find_by(slug: params[:slug].to_s.downcase) ||
      raise(Api::Error.not_found("no page #{params[:slug]} in #{project.key}.", hint: "see them with mt doc."))
    if page.cover?
      raise Api::Error.validation("the cover is the brief: lint reads capabilities and cross-cutting pages.", hint: "mt doc lint <slug> or mt doc lint --all.")
    end

    lint = Page::Lint.new(page)
    render_lints([ lint ], summary: "#{page.slug}: #{counts(lint)}.", breadcrumbs: [ "mt doc #{page.slug}", "mt doc edit #{page.slug} --file <f.md>" ])
  end

  private

  def render_lints(lints, summary:, breadcrumbs: [ "mt doc lint <slug>" ])
    markdown = lints.map { page_markdown(it) }.join("\n\n")
    render_ok({ pages: lints.map(&:to_h), errors: lints.sum { it.errors.size }, warnings: lints.sum { it.warnings.size },
                markdown: [ markdown.presence, (summary if lints.size != 1) ].compact.join("\n\n") + "\n" },
      summary: summary, breadcrumbs: breadcrumbs)
  end

  # board · Tablero: 1 error, no warnings
  #   Opening sentence: «…»
  #   3 rules, 2 questions
  #   Error: D-99 does not exist in PG.
  def page_markdown(lint)
    lead = lint.reading&.lead
    [ "#{lint.page.slug} · #{lint.page.title}: #{counts(lint)}",
      *("  Opening sentence: «#{lead.truncate(100)}»" if lead),
      *("  #{plural(lint.rules.size, 'rule')}, #{plural(lint.questions.size, 'question')}" if lint.reading),
      *lint.errors.map { "  Error: #{it.message}" },
      *lint.warnings.map { "  Warning: #{it.message}" } ].join("\n")
  end

  def counts(lint)
    return "reads well" if lint.findings.empty?

    [ plural(lint.errors.size, "error"), plural(lint.warnings.size, "warning") ].join(", ")
  end

  # "4 pages in PG: 1 with errors, 1 with warnings, 2 read well."
  def all_summary(lints)
    return "No pages to lint in #{project.key}: create one with mt doc create <slug> --title \"…\"." if lints.empty?

    with_errors = lints.count { it.errors.any? }
    with_warnings = lints.count { it.errors.empty? && it.warnings.any? }
    parts = [ ("#{with_errors} with errors" if with_errors > 0), ("#{with_warnings} with warnings" if with_warnings > 0),
              ("#{lints.size - with_errors - with_warnings} read well" if lints.size > with_errors + with_warnings) ].compact
    "#{plural(lints.size, 'page')} in #{project.key}: #{Api::Markdown::Formatting.sentence(parts)}."
  end

  def plural(...) = Api::Markdown::Formatting.plural(...)
end
