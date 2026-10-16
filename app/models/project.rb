# Un producto. Su contexto vive en `brief` (markdown) y su roadmap son los
# hitos ordenados, cada uno con sus historias ordenadas.
class Project < ApplicationRecord
  BRIEF_TEMPLATE = <<~MARKDOWN.freeze
    ## Visión

    ## Principios

    ## Fuera de alcance

    ## Glosario
  MARKDOWN

  has_many :milestones, -> { order(:position) }, inverse_of: :project
  has_many :stories, inverse_of: :project

  normalizes :key, with: -> { it.strip.upcase }

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :key, presence: true, uniqueness: true, format: { with: /\A[A-Z]{2,5}\z/, message: "debe tener de 2 a 5 letras" }

  attribute :brief, default: BRIEF_TEMPLATE
  before_validation :generate_slug, on: :create

  def to_param = slug

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

  # Reserva el siguiente número de historia (o respeta uno dado) sin reutilizar nunca uno anterior.
  def reserve_story_number!(number = nil)
    with_lock do
      number ||= last_story_number + 1
      update_columns(last_story_number: [ last_story_number, number ].max)
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
