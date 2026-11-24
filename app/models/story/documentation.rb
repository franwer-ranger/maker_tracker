# La historia como diff (MT-91, D-91): una historia declara las capacidades
# que cambia (`capabilities`) y cerrarla deja sus páginas al día.
#
# Al pasar a Hecha, el evento de cierre (`story.state_changed` a done) enlaza
# en `data.docs` las páginas que se editaron (`page.edited`) desde que empezó
# el trabajo, con su versión, y en `data.docs_pending` las que no. Esas quedan
# «documentación pendiente» hasta que un `story.documented` posterior las
# enlace (`mt done` otra vez tras editarlas). Todo se deriva de los eventos,
# sin columna: quitar la capacidad de la historia (si al final no la cambió) o
# borrar la página también lo resuelve. Un cierre
# sin `docs_pending` (los de antes de MT-91 y los de historias sin
# capacidades) nunca deja nada pendiente.
module Story::Documentation
  extend ActiveSupport::Concern

  included do
    # Con alguna capacidad declarada. Filtra en SQL: casi ninguna tiene.
    scope :with_capabilities, -> { where("json_array_length(COALESCE(json_extract(stories.properties, '$.capabilities'), '[]')) > 0") }
  end

  class_methods do
    # Las Hechas con documentación pendiente (de un proyecto o de todos), con
    # sus páginas: [[story, pages]]. El SQL deja solo las que tienen
    # `docs_pending` en su último cierre; si siguen pendientes (lo documentado
    # después, las capacidades y páginas de hoy) se decide en Ruby sobre ellas.
    def documentation_pending
      last_closes = Event.where(action: "story.state_changed").where("json_extract(events.data, '$.docs_pending') IS NOT NULL").where(<<~SQL.squish)
        events.id = (SELECT closes.id FROM events closes WHERE closes.story_id = events.story_id AND closes.action = 'story.state_changed'
          AND json_extract(closes.data, '$.to') = 'done' ORDER BY closes.occurred_at DESC, closes.id DESC LIMIT 1)
      SQL
      done.with_capabilities.where(id: last_closes.select(:story_id)).includes(:project).order(:id)
        .map { [ it, it.pending_documentation ] }.reject { |_story, pages| pages.empty? }
    end
  end

  # Lo que se guarda en el evento de cierre: `docs` (las editadas desde que
  # empezó) y `docs_pending` (las demás). Vacío si no cambia ninguna capacidad.
  def documentation_on_close
    pages = changed_capabilities.to_a
    return {} if pages.empty?

    updated = pages_edited_since(pages, work_started_at)
    { docs: updated.map { page_link(it) }.presence, docs_pending: (pages - updated).map { { page_id: it.id, slug: it.slug } }.presence }.compact
  end

  # Las páginas que siguen pendientes desde el último cierre.
  def pending_documentation
    return [] unless done? && capabilities.any?

    close = last_close or return []
    pending = Array(close.data["docs_pending"]).map { it["page_id"] }
    return [] if pending.empty?

    documented = events.where(action: "story.documented", id: close.id..).flat_map { Array(it.data["docs"]).map { |doc| doc["page_id"] } }
    changed_capabilities.select { pending.include?(it.id) && documented.exclude?(it.id) }
  end

  def documentation_pending? = pending_documentation.any?

  # Enlaza las pendientes que ya se editaron (`mt done` otra vez). Devuelve
  # las enlazadas. Sin pendientes no bloquea: casi ninguna historia tiene.
  def document!(actor:)
    return [] if pending_documentation.empty?

    with_lock do
      pages = pages_edited_since(pending_documentation, last_close.occurred_at)
      next [] if pages.empty?

      record_event!("story.documented", actor: actor, story: self, data: { docs: pages.map { page_link(it) } })
      pages
    end
  end

  # El último paso a Hecha.
  def last_close = events.where(action: "story.state_changed").where("json_extract(data, '$.to') = 'done'").recent_first.first

  # Desde cuándo cuentan las ediciones: el último paso a En curso o, si nunca
  # lo tuvo, su creación.
  def work_started_at
    events.where(action: "story.state_changed").where("json_extract(data, '$.to') = 'in_progress'").maximum(:occurred_at) || created_at
  end

  private

  def page_link(page) = { page_id: page.id, slug: page.slug, version: page.version }

  def pages_edited_since(pages, since)
    return [] if pages.empty?

    edited = project.events.where(action: "page.edited", occurred_at: since..)
      .where("json_extract(data, '$.page_id') IN (?)", pages.map(&:id)).pluck(Arel.sql("json_extract(data, '$.page_id')"))
    pages.select { edited.include?(it.id) }
  end
end
