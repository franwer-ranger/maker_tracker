# Un producto. Su contexto vive en su documentación (`pages`, MT-89), cuya
# portada es el brief (D-92), y su roadmap son los hitos ordenados, cada uno con
# sus historias ordenadas.
class Project < ApplicationRecord
  include Eventable

  # El brief vivía aquí hasta MT-89; ahora es la portada (Page). Las columnas se
  # quedan en la tabla, sin uso, para poder deshacer la migración.
  self.ignored_columns += %w[brief brief_version]

  BRIEF_TEMPLATE = <<~MARKDOWN.freeze
    ## Visión

    ## Principios

    ## Autonomía

    Los agentes pueden crear ideas y historias en Definiendo, escribir el cuerpo de las historias, comentar, reordenar dentro de un hito con motivo y editar las páginas de la documentación que cambia la historia en la que trabajan. Preguntan antes de marcar una historia como Lista, tocar el brief, crear o reordenar hitos, cerrar un hito, o crear, separar, juntar o borrar capacidades.

    ## Fuera de alcance

    ## Dónde se prueba

    Testing o producción, con su URL, en una línea: aquí se prueba lo que los agentes dan por hecho.

    ## Glosario
  MARKDOWN

  has_many :milestones, -> { order(:position) }, inverse_of: :project
  has_many :stories, inverse_of: :project
  has_many :questions, through: :stories
  has_many :decisions, -> { order(:number) }, inverse_of: :project
  has_many :events, inverse_of: :project
  has_many :pages, inverse_of: :project
  has_one :cover, -> { where(kind: :cover) }, class_name: "Page", inverse_of: :project, autosave: true
  # El logo del producto (MT-96; lo usan MT-85 y MT-40): una imagen en Active Storage.
  has_one_attached :logo do |attachable|
    attachable.variant :thumb, resize_to_limit: [ 128, 128 ]
  end
  validate :logo_is_an_image, if: -> { logo.attached? }

  normalizes :key, with: -> { it.strip.upcase }

  validates :name, presence: true
  # Sale del nombre: sin nombre, el error que importa es el del nombre.
  validates :slug, presence: true, uniqueness: true, if: -> { name.present? }
  validates :key, presence: true, uniqueness: true, format: { with: /\A[A-Z]{2,5}\z/, message: :key_format }

  before_validation :generate_slug, on: :create
  before_validation -> { self.brief = BRIEF_TEMPLATE unless cover }, on: :create

  # El brief es la portada (D-92): se lee y se escribe en ella.
  def brief = cover&.body.to_s
  def brief_version = cover&.version || 1

  def brief=(text)
    (cover || build_cover(kind: :cover, slug: Page::COVER_SLUG)).body = text.to_s
  end

  def to_param = slug

  # Operaciones de dominio: cada una hace su cambio y registra su evento.

  def self.create_with_event!(attributes, actor:)
    transaction do
      create!(attributes).tap { it.record_event!("project.created", actor: actor) }
    end
  end

  def create_milestone!(attributes, actor:)
    transaction do
      milestones.create!(attributes).tap do |milestone|
        record_event!("milestone.created", actor: actor, data: { milestone_id: milestone.id, title: milestone.title })
      end
    end
  end

  # `data` se añade al evento (la daily marca así las ideas que propone).
  def create_story!(attributes, actor:, data: {})
    transaction do
      stories.create!(attributes).tap do |story|
        record_event!("story.created", actor: actor, story: story, data: { state: story.state, milestone_id: story.milestone_id }.merge(data))
      end
    end
  end

  # Con `version:` (la del brief que leyó quien edita) falla con
  # Versioned::Conflict si el brief ya cambió.
  def edit_brief!(text, actor:, version: nil) = cover.edit!({ body: text.to_s }, actor: actor, version: version)

  # Una página nueva de la documentación (la portada ya existe).
  def create_page!(attributes, actor:)
    transaction do
      pages.create!(attributes).tap do |page|
        record_event!("page.created", actor: actor, data: { page_id: page.id, slug: page.slug, kind: page.kind, title: page.title })
      end
    end
  end

  # Una decisión rige las capacidades que se le dan (`capabilities`, páginas),
  # las que cambia su historia y las de la que sustituye (MT-90): así una
  # capacidad no se queda sin la decisión vigente al sustituir la anterior.
  def record_decision!(attributes, actor:, capabilities: [])
    attributes = attributes.to_h.symbolize_keys
    inherited = attributes[:story]&.changed_capabilities.to_a + attributes[:supersedes]&.capabilities.to_a
    pages = (capabilities + inherited).uniq.sort_by(&:slug)

    transaction do
      decisions.create!(attributes.merge(actor: actor, capabilities: pages)).tap do |decision|
        data = { number: decision.number, capabilities: pages.map(&:slug).presence }.compact
        record_event!("decision.recorded", actor: actor, story: decision.story, data: data)
      end
    end
  end

  # El proyecto despliega con mt (MT-46, D-64): se activa solo con la primera
  # llamada a `mt deployed`, sin columna ni configuración.
  def deploys? = events.exists?(action: "project.deployed")

  # Las historias Hechas y sin desplegar: lo que `mt deployed` puede marcar,
  # con los commits y el PR de su evento de Hecha. En un proyecto que ya
  # despliega, solo las hechas desde su primer despliegue: las de antes no
  # esperan a ninguno (sin la QA, MT-98, nada más las distingue).
  # [[story, event]] (el evento puede faltar en historias antiguas).
  def deploy_candidates
    stories = self.stories.done.where(deployed_at: nil).includes(:milestone).order(:number).to_a
    done = events.where(story_id: stories.map(&:id), action: "story.state_changed").order(:occurred_at, :id)
      .select { it.data["to"] == "done" }.index_by(&:story_id) # el último gana
    since = events.where(action: "project.deployed").minimum(:occurred_at)
    stories.map { [ it, done[it.id] ] }.select { |_, event| since.nil? || (event && event.occurred_at >= since) }
  end

  # `mt deployed`: marca como desplegadas las historias `numbers` (solo las
  # candidatas, así llamar dos veces es idempotente) y deja un evento del
  # proyecto aunque no marque ninguna. `warnings` son los avisos del CLI (las
  # que dio por desplegadas sin nada que comprobar). Devuelve las marcadas.
  def deploy!(sha:, numbers:, actor:, warnings: [])
    transaction do
      wanted = numbers.to_set
      marked = deploy_candidates.map(&:first).select { it.number.in?(wanted) && it.deployed!(sha: sha, actor: actor) }
      record_event!("project.deployed", actor: actor, data: { sha: sha, stories: marked.map(&:number), warnings: warnings.presence }.compact)
      marked
    end
  end

  def last_editor = cover.last_editor

  # El hito en el que se trabaja: el primero abierto.
  def current_milestone = milestones.open.first

  def last_activity_at = events.maximum(:occurred_at)

  # Historias sin hito.
  def ideas = stories.where(milestone: nil).ordered

  # La regla de `mt next`: la primera historia Lista y no bloqueada,
  # recorriendo los hitos abiertos en orden.
  def next_story
    done = stories.done.pluck(:number)
    milestones.open.each do |milestone|
      story = milestone.stories.ready.ordered.includes(:questions).find { !it.blocked?(done_numbers: done) }
      return story if story
    end
    nil
  end

  # Reserva el siguiente número de historia, decisión o hito (o respeta uno dado)
  # sin reutilizar nunca uno anterior. Ver NumberedInProject.
  def reserve_number!(kind, number = nil)
    column = "last_#{kind}_number"
    with_lock do
      number ||= self[column] + 1
      update_columns(column => [ self[column], number ].max)
      number
    end
  end

  private

  def logo_is_an_image
    errors.add(:logo, :not_an_image) unless Attachable::IMAGE_TYPES.include?(logo.content_type)
    errors.add(:logo, :too_big) if logo.byte_size > 5.megabytes
  end

  def generate_slug
    return if slug.present? || name.blank?

    base = name.parameterize
    self.slug = base
    suffix = 1
    self.slug = "#{base}-#{suffix += 1}" while Project.exists?(slug: slug)
  end
end
