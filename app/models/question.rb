# Una pregunta de un agente en una historia, con sus opciones y su
# recomendación (MT-29). Por defecto bloquea: una historia con alguna pregunta
# abierta y bloqueante está bloqueada por quien responde (derivado, como
# `blocked_by`). Una no bloqueante deja seguir al agente con la recomendada.
#
# `reversible` admite nulo: sin indicar, no se asume irreversible. Las
# opciones y la respuesta se cuentan desde 1, como en `mt answer PG-49 2`.
class Question < ApplicationRecord
  # Ya está respondida.
  class AlreadyAnswered < StandardError
    attr_reader :question

    def initialize(question)
      @question = question
      super("La pregunta #{question.reference} ya está respondida")
    end
  end

  belongs_to :story
  belongs_to :actor
  belongs_to :answered_by, class_name: "Actor", optional: true
  has_one :project, through: :story

  attribute :blocking, default: true
  attribute :options, default: -> { [] }

  scope :open, -> { where(answered_at: nil) }
  scope :answered, -> { where.not(answered_at: nil) }
  scope :blocking, -> { where(blocking: true) }
  scope :oldest_first, -> { order(:created_at, :id) }

  normalizes :title, with: -> { it.strip }
  normalizes :context, with: -> { it.to_s.strip }

  validates :title, presence: true
  validate :options_are_enough_texts
  validate :recommended_is_an_option
  validate :non_blocking_has_recommended
  validate :answer_is_an_option

  # "Q12": con el id, `mt answer PG-49 2 --question 12` elige entre varias abiertas.
  def reference = "Q#{id}"

  def open? = answered_at.nil?

  # Quita espacios y opciones vacías; sin lista, queda vacía y falla la validación.
  def options=(value)
    super(Array(value).map { it.is_a?(String) ? it.strip : it })
  end

  def option_text(number) = number && options[number - 1]

  def recommended_text = option_text(recommended)

  def answer_text = option_text(answer)

  # Contesta con una opción (su número) y una nota opcional.
  def answer!(option:, note: nil, actor:)
    raise AlreadyAnswered, self if answered?

    update!(answer: option, answer_note: note.to_s.strip.presence, answered_by: actor, answered_at: Time.current)
  end

  def answered? = !open?

  # Las que quedaron fuera, con su número: [[1, "Quitarla y publicar"], [3, "…"]].
  def discarded_options
    options.each_with_index.map { |text, i| [ i + 1, text ] }.reject { |number, _| number == answer }
  end

  private

  def options_are_enough_texts
    unless options.is_a?(Array) && options.all? { it.is_a?(String) && it.present? }
      return errors.add(:options, :not_texts)
    end

    errors.add(:options, :too_few) if options.size < 2
  end

  def recommended_is_an_option
    errors.add(:recommended, :not_an_option, count: options.size) if recommended && !(1..options.size).cover?(recommended)
  end

  def non_blocking_has_recommended
    errors.add(:recommended, :required_when_non_blocking) if !blocking? && recommended.nil?
  end

  def answer_is_an_option
    errors.add(:answer, :not_an_option, count: options.size) if answered_at && !(1..options.size).cover?(answer)
  end
end
