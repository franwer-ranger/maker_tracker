# Un producto. Su contexto vive en `brief` (markdown) y su roadmap son los
# hitos ordenados, cada uno con sus historias ordenadas.
class Project < ApplicationRecord
  include Eventable

  BRIEF_TEMPLATE = <<~MARKDOWN.freeze
    ## Visión

    ## Principios

    ## Fuera de alcance

    ## Glosario
  MARKDOWN

  has_many :milestones, -> { order(:position) }, inverse_of: :project
  has_many :stories, inverse_of: :project
  has_many :decisions, -> { order(:number) }, inverse_of: :project
  has_many :events, inverse_of: :project

  normalizes :key, with: -> { it.strip.upcase }

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :key, presence: true, uniqueness: true, format: { with: /\A[A-Z]{2,5}\z/, message: "debe tener de 2 a 5 letras" }

  attribute :brief, default: BRIEF_TEMPLATE
  before_validation :generate_slug, on: :create

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

  def create_story!(attributes, actor:)
    transaction do
      stories.create!(attributes).tap do |story|
        record_event!("story.created", actor: actor, story: story, data: { state: story.state, milestone_id: story.milestone_id })
      end
    end
  end

  def edit_brief!(text, actor:)
    return false if text == brief

    transaction do
      update!(brief: text)
      record_event!("brief.edited", actor: actor)
    end
  end

  def record_decision!(attributes, actor:)
    transaction do
      decisions.create!(attributes.merge(actor: actor)).tap do |decision|
        record_event!("decision.recorded", actor: actor, story: decision.story, data: { number: decision.number })
      end
    end
  end

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
      story = milestone.stories.ready.ordered.find { !it.blocked?(done_numbers: done) }
      return story if story
    end
    nil
  end

  # Reserva el siguiente número de historia o decisión (o respeta uno dado)
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

  def generate_slug
    return if slug.present? || name.blank?

    base = name.parameterize
    self.slug = base
    suffix = 1
    self.slug = "#{base}-#{suffix += 1}" while Project.exists?(slug: slug)
  end
end
