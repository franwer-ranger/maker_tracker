# Algo a construir. Propiedades arriba (`properties`) y markdown libre abajo
# (`body`). Sin hito, está en la bandeja de ideas.
class Story < ApplicationRecord
  STATE_NAMES = {
    "idea" => "Idea",
    "defining" => "Definiendo",
    "ready" => "Lista",
    "in_progress" => "En curso",
    "done" => "Hecha"
  }.freeze

  BODY_TEMPLATE = <<~MARKDOWN.freeze
    ## Contexto

    ## Historia

    ## Criterios de aceptación

    ## Fuera de alcance

    ## Notas para quien lo construya

    ## Preguntas abiertas
  MARKDOWN

  belongs_to :project
  belongs_to :milestone, optional: true
  belongs_to :claimed_by, class_name: "Actor", optional: true
  has_many :comments, -> { order(:created_at, :id) }, inverse_of: :story
  has_many :decisions, inverse_of: :story
  has_many :questions, -> { oldest_first }, inverse_of: :story

  include NumberedInProject
  include Operations
  include Qa
  include Usage

  enum :state, STATE_NAMES.keys.index_by(&:itself), default: :idea, validate: true
  positioned on: %i[project milestone]
  store_accessor :properties, :mockup, :labels, :blocked_by

  attribute :body, default: BODY_TEMPLATE

  scope :ordered, -> { order(:position) }

  validates :title, presence: true
  validate :milestone_in_same_project
  validate :mockup_is_http_url
  validate :labels_are_texts
  validate :blocked_by_are_stories_of_project

  def self.human_state(state) = STATE_NAMES.fetch(state.to_s)

  def human_state = self.class.human_state(state)

  def reference = "#{project.key}-#{number}"

  # Las URLs usan el número de la historia en su proyecto: /p/postgram/stories/49.
  def to_param = number&.to_s

  def labels = super || []
  def blocked_by = super || []

  # Acepta una lista o un texto ("ux, móvil"). Quita espacios sobrantes y repetidos.
  def labels=(value)
    value = value.split(",") if value.is_a?(String)
    super(Array(value).map { it.is_a?(String) ? it.strip : it }.compact_blank.uniq)
  end

  # Acepta una lista o un texto ("12, 14"). Lo que no sea un número se queda para que falle la validación.
  def blocked_by=(value)
    value = value.split(/[\s,]+/) if value.is_a?(String)
    super(Array(value).compact_blank.map { Integer(it, exception: false) || it }.uniq)
  end

  def mockup=(value)
    super(value.presence&.strip)
  end

  # Bloqueada no es un estado: se deriva de `blocked_by` y de las preguntas
  # abiertas que bloquean (MT-29).
  def blocked?(done_numbers: nil) = pending_blockers(done_numbers: done_numbers).any? || blocking_questions.any?

  # Números de `blocked_by` que aún no están hechos.
  def pending_blockers(done_numbers: nil)
    return [] if blocked_by.empty?

    done_numbers ||= project.stories.done.where(number: blocked_by).pluck(:number)
    blocked_by - done_numbers
  end

  # Preguntas abiertas que la bloquean: la historia espera a quien responde.
  # Con `includes(:questions)` no consulta una vez por historia.
  def blocking_questions = questions.select { it.open? && it.blocking? }

  # Las abiertas, bloqueen o no, y las respondidas.
  def open_questions_asked = questions.select(&:open?)

  def answered_questions = questions.select(&:answered?)

  # Algún criterio (`- [ ]` / `- [x]`) en el cuerpo.
  # Criterios marcados y totales de un cuerpo, para el resumen de ediciones (MT-31).
  def self.criteria_counts(body)
    boxes = body.to_s.scan(/^\s*[-*] \[([ xX])\]/).flatten
    { done: boxes.count { it != " " }, total: boxes.size }
  end

  def criteria? = body.to_s.match?(/^\s*[-*] \[[ xX]\]/)

  # En Definiendo y sin ningún criterio.
  def missing_criteria? = defining? && !criteria?

  # Lo que incumple la regla para pasar a Lista (`PRODUCT.md`). Es un aviso,
  # no una validación: la UI lo enseña (readiness_issues) y la API lo devuelve
  # como warning, en inglés.
  def readiness_problems
    problems = []
    problems << :open_questions if open_questions?
    problems << :ui_without_mockup if labels.include?("ui") && mockup.blank?
    problems
  end

  READINESS_ISSUES = {
    open_questions: "Tiene preguntas abiertas sin responder.",
    ui_without_mockup: "Tiene la label «ui» y no tiene mockup."
  }.freeze

  def readiness_issues = readiness_problems.map { READINESS_ISSUES.fetch(it) }

  def open_questions?
    open_questions_text.present?
  end

  # El texto bajo «## Preguntas abiertas» del cuerpo, o nil si está vacío.
  def open_questions_text
    body.to_s[/^## Preguntas abiertas\s*$(.*?)(?=^## |\z)/m, 1].to_s.strip.presence
  end

  # Las historias que tienen a esta en su `blocked_by`.
  def blocking
    project.stories.where(<<~SQL.squish, number)
      EXISTS (SELECT 1 FROM json_each(stories.properties, '$.blocked_by') WHERE json_each.value = ?)
    SQL
  end

  private

  def milestone_in_same_project
    errors.add(:milestone, :other_project) if milestone && milestone.project_id != project_id
  end

  def mockup_is_http_url
    return if mockup.blank?

    uri = URI.parse(mockup)
    errors.add(:mockup, :not_http_url) unless uri.is_a?(URI::HTTP) && uri.host.present?
  rescue URI::InvalidURIError
    errors.add(:mockup, :not_http_url)
  end

  def labels_are_texts
    errors.add(:labels, :not_texts) unless labels.is_a?(Array) && labels.all?(String)
  end

  def blocked_by_are_stories_of_project
    return errors.add(:blocked_by, :not_a_list) unless blocked_by.is_a?(Array)

    invalid = blocked_by.reject { it.is_a?(Integer) }
    return errors.add(:blocked_by, :not_numbers, values: invalid.join(", ")) if invalid.any?

    errors.add(:blocked_by, :itself) if number && blocked_by.include?(number)
    missing = blocked_by - project.stories.where(number: blocked_by).pluck(:number) if project
    errors.add(:blocked_by, :missing_stories, numbers: missing.join(", ")) if missing.present?
  end
end
