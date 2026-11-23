# Una página de la documentación del producto (MT-89, D-91): la portada, una
# capacidad (lo que el producto hace, p. ej. «Tablero») o una transversal (lo
# que atraviesa varias, p. ej. «Agentes»). Markdown, con versión como las
# historias (MT-37). Se cita por su `slug`, que no cambia.
#
# La portada es el brief (D-92): hay una por proyecto, con slug `cover`, y sus
# ediciones son `brief.edited`, así que `mt brief` y la UI del brief la leen y
# la escriben. Las demás registran `page.created`, `page.edited` y
# `page.deleted` con su `page_id` en `data`.
class Page < ApplicationRecord
  include Eventable
  include Versioned

  COVER_SLUG = "cover"
  # Los subcomandos de `mt doc` no pueden ser el slug de una página.
  RESERVED_SLUGS = %w[create edit delete list show].freeze
  EDITABLE_FIELDS = %w[title icon area body kind].freeze

  belongs_to :project
  # Las decisiones que rigen la página (MT-90). Al borrarla se va el enlace, no la decisión.
  has_many :decision_capabilities, dependent: :delete_all
  has_many :decisions, through: :decision_capabilities

  enum :kind, { cover: "cover", capability: "capability", crosscutting: "crosscutting" }, default: :capability, validate: true

  normalizes :slug, with: -> { it.strip.downcase }
  normalizes :icon, :area, with: -> { it.strip.presence }

  # La de la portada sale del nombre del proyecto: si falta, el error es el del nombre.
  validates :title, presence: true, unless: :cover?
  validates :slug, presence: true, uniqueness: { scope: :project_id },
    format: { with: /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/, message: :slug_format }
  validates :slug, exclusion: { in: RESERVED_SLUGS, message: :reserved_slug }
  validate :cover_is_the_cover
  validate :cover_changes_only_body, if: -> { cover? && persisted? }

  # La portada se llama como el proyecto si nadie le pone otro título.
  before_validation -> { self.title = project&.name if cover? && title.blank? }

  # La portada primero; después las capacidades y las transversales, por área y título.
  scope :ordered, -> { in_order_of(:kind, kinds.values).order(Arel.sql("area IS NULL"), :area, :title) }
  scope :documentation, -> { where.not(kind: :cover) }

  # Sus eventos, del más reciente al más antiguo. Los de la portada son los del
  # brief; los de las demás, sus cambios y el registro de las decisiones que la
  # rigen (MT-90), también las ya sustituidas.
  def history
    events = project.events.recent_first
    return events.where(action: "brief.edited") if cover?

    events.where("json_extract(data, '$.page_id') = ?", id)
      .or(events.where(action: "decision.recorded").where("json_extract(data, '$.number') IN (?)", decisions.pluck(:number)))
  end

  # Título, icono, área, tipo y cuerpo. Con `version:` (la que leyó quien edita)
  # falla con Versioned::Conflict si la página ya cambió, sin guardar nada. La
  # portada solo cambia de cuerpo: otro título, icono, área o tipo es un error
  # de validación.
  def edit!(attributes, actor:, version: nil)
    attributes = attributes.to_h.stringify_keys
    unknown = attributes.keys - EDITABLE_FIELDS
    raise ArgumentError, "No se puede editar con edit!: #{unknown.join(', ')}" if unknown.any?

    transaction do
      lock!
      assign_attributes(attributes)
      fields = changed & EDITABLE_FIELDS
      next false if fields.empty?

      check_version!(version)

      bump_version
      save!
      if cover?
        record_event!("brief.edited", actor: actor, data: { page_id: id })
      else
        record_event!("page.edited", actor: actor, data: { page_id: id, slug: slug, fields: fields })
      end
    end
  end

  def destroy_with_event!(actor:)
    raise ArgumentError, "La portada no se borra: es el brief" if cover?

    transaction do
      destroy!
      record_event!("page.deleted", actor: actor, data: { page_id: id, slug: slug, title: title })
    end
  end

  def last_editor
    event = history.where(action: %w[brief.edited page.edited page.created]).includes(:actor).first
    [ event&.actor, event&.occurred_at ]
  end

  private

  def cover_is_the_cover
    errors.add(:slug, :cover_slug) if cover? != (slug == COVER_SLUG)
    errors.add(:kind, :cover_kind) if kind_changed? && persisted? && (kind_was == "cover" || cover?)
  end

  def cover_changes_only_body
    %w[title icon area].each { errors.add(it, :cover_body_only) if attribute_changed?(it) }
  end
end
