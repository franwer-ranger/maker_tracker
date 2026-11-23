# La documentación del producto (MT-89): `mt doc` lista las páginas, `mt doc
# tablero` enseña una, `mt doc edit tablero --file f.md` la cambia (con la
# versión del frontmatter, como `mt edit`) y `mt doc create` / `mt doc delete`
# crean y borran capacidades y transversales. La portada (`cover`) es el brief:
# se lee y se edita igual, pero no se crea ni se borra.
class Api::PagesController < Api::BaseController
  def index
    pages = project.pages.ordered.to_a
    summary = index_summary(pages)
    rows = pages.map { [ it.slug, Api::Markdown::Page.kind_words(it.kind), it.title, it.area.to_s ] }
    render_ok({ pages: pages.map { page_data(it) },
                markdown: [ summary, Api::Markdown::Formatting.table(rows).join("\n").presence ].compact.join("\n\n") + "\n" },
      summary: summary, breadcrumbs: [ "mt doc <slug>", "mt doc create <slug> --title \"…\"" ])
  end

  def show
    render_ok({ page: page_data(page), markdown: Api::Markdown::Page.new(page).to_s },
      summary: "#{label(page)} (version #{page.version}).", breadcrumbs: [ "mt doc edit #{page.slug} --file <f.md>" ])
  end

  # `mt doc create tablero --title "Tablero" [--type …] [--area …] [--icon …] [--file f.md]`:
  # los campos sueltos mandan sobre el documento. Sin tipo, es una capacidad.
  def create
    attributes = page_attributes.except("version")
    attributes["slug"] = params[:slug].presence || attributes["slug"]
    attributes["kind"] = attributes["kind"].presence || "capability"
    if attributes["kind"] == "cover"
      raise Api::Error.validation("the cover already exists: it is the brief.", hint: "edit it with mt doc edit cover --file <f.md> or mt brief --file <f.md>.")
    end

    created = project.create_page!(attributes, actor: Current.actor)
    render_ok({ page: page_data(created) }, status: :created,
      summary: "#{label(created)} created.", breadcrumbs: [ "mt doc #{created.slug}", "mt doc edit #{created.slug} --file <f.md>" ])
  end

  # `mt doc edit tablero --file f.md`. El `version:` del frontmatter es la que
  # leyó quien edita: si la página ya cambió, CONFLICT y no se guarda nada.
  def update
    attributes = page_attributes
    version = version_param(attributes.delete("version"))
    if attributes.key?("slug") && attributes["slug"].to_s.downcase != page.slug
      raise Api::Error.validation("editing does not change the slug.", hint: "create the page with the new slug (mt doc create) and delete this one (mt doc delete #{page.slug}).")
    end
    attributes = attributes.slice(*Page::EDITABLE_FIELDS)
    attributes.delete("body") if attributes.key?("body") && attributes["body"].to_s.strip == page.body.to_s.strip
    attributes.delete("kind") if attributes["kind"].blank?

    changed = page.edit!(attributes, actor: Current.actor, version: version)
    render_ok({ page: page_data(page) },
      summary: changed ? "#{label(page)} edited by #{Current.actor.name}." : "#{label(page)} did not change.",
      breadcrumbs: [ "mt doc #{page.slug}" ])
  end

  def destroy
    if page.cover?
      raise Api::Error.validation("the cover is not deleted: it is the brief.", hint: "edit it with mt doc edit cover --file <f.md>.")
    end

    page.destroy_with_event!(actor: Current.actor)
    render_ok({ page: page_data(page) }, summary: "#{label(page)} deleted.", breadcrumbs: [ "mt doc" ])
  end

  private

  def page
    @page ||= project.pages.find_by(slug: params[:slug].to_s.downcase) ||
      raise(Api::Error.not_found("no page #{params[:slug]} in #{project.key}.", hint: "see them with mt doc."))
  end

  # Atributos desde `markdown` (formato de ver), desde campos sueltos o ambos.
  def page_attributes
    fields = params.permit(:version, :title, :icon, :area, :body, :type).to_h
    fields["kind"] = fields.delete("type") if fields.key?("type")
    return fields if params[:markdown].nil?

    Api::PageDocument.parse(params[:markdown]).merge(fields)
  end

  def version_param(value)
    return if value.blank?

    Integer(value.to_s, exception: false) || raise(Api::Error.validation("version must be a whole number, not #{value}.", hint: "use the version: line of mt doc #{page.slug}."))
  end

  # "tablero · Tablero (capability)"
  def label(page) = "#{page.slug} · #{page.title} (#{Api::Markdown::Page.kind_words(page.kind)})"

  # "4 pages in MT: the cover, 2 capabilities and 1 cross-cutting."
  def index_summary(pages)
    counts = pages.group_by(&:kind).transform_values(&:size)
    parts = [ ("the cover" if counts["cover"]), (Api::Markdown::Formatting.plural(counts["capability"], "capability", "capabilities") if counts["capability"]),
              ("#{counts['crosscutting']} cross-cutting" if counts["crosscutting"]) ].compact
    "#{Api::Markdown::Formatting.plural(pages.size, 'page')} in #{project.key}: #{Api::Markdown::Formatting.sentence(parts)}."
  end

  def page_data(page)
    { slug: page.slug, type: page.kind, title: page.title, icon: page.icon, area: page.area, version: page.version, body: page.body }
  end
end
