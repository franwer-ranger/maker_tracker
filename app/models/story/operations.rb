# Operaciones de dominio de una historia. La UI de M1 y la API de M2 usan estos
# métodos: cada uno hace su cambio y registra su evento en la misma
# transacción. Si no cambia nada, no hay evento y devuelven false.
module Story::Operations
  extend ActiveSupport::Concern

  include Eventable
  include Versioned

  EDITABLE_FIELDS = %w[title body mockup labels blocked_by].freeze

  # Otro actor ya tiene la historia.
  class ClaimedByOther < StandardError
    attr_reader :story

    def initialize(story)
      @story = story
      super("#{story.reference} la tiene #{story.claimed_by.name}")
    end
  end

  included do
    has_many :events, inverse_of: :story
  end

  # Sus eventos, del más reciente al más antiguo.
  def history = events.recent_first

  # Título, cuerpo y propiedades. El evento guarda qué campos cambiaron, no su
  # contenido. Con `version:` (la que leyó quien edita) falla con
  # Versioned::Conflict si la historia ya cambió, sin guardar nada.
  def edit!(attributes, actor:, version: nil)
    attributes = attributes.to_h.stringify_keys
    unknown = attributes.keys - EDITABLE_FIELDS
    raise ArgumentError, "No se puede editar con edit!: #{unknown.join(', ')}" if unknown.any?

    transaction do
      lock!
      before = EDITABLE_FIELDS.index_with { public_send(it) }
      assign_attributes(attributes)
      fields = EDITABLE_FIELDS.reject { public_send(it) == before[it] }
      next false if fields.empty?

      check_version!(version)

      bump_version
      save!
      record_event!("story.edited", actor: actor, story: self, data: { fields: fields })
    end
  end

  # Quién editó el contenido por última vez y cuándo.
  def last_editor
    event = events.where(action: "story.edited").recent_first.includes(:actor).first
    [ event&.actor, event&.occurred_at ]
  end

  # Pasar a En curso la reclama para el actor (si es de otro, falla). Volver
  # de En curso a un estado anterior la libera. Pasar a Hecha mantiene el dueño.
  # `data` se añade al evento (commits y PR al terminar) y `reason`, su motivo.
  def move_to!(new_state, actor:, data: {}, reason: nil)
    new_state = new_state.to_s
    raise ArgumentError, "Estado desconocido: #{new_state}" unless self.class.states.key?(new_state)

    with_lock do
      from = state
      raise ClaimedByOther, self if new_state == "in_progress" && claimed_by && claimed_by != actor
      next false if from == new_state

      data = { from: from, to: new_state }.merge(data.compact_blank)
      if new_state == "in_progress"
        unless claimed_by
          assign_attributes(claimed_by: actor, claimed_at: Time.current)
          data[:claimed] = true
        end
      elsif from == "in_progress" && new_state != "done" && claimed_by
        assign_attributes(claimed_by: nil, claimed_at: nil)
        data[:released] = true
      end

      update!(state: new_state)
      record_event!("story.state_changed", actor: actor, story: self, data: data, reason: reason)
    end
  end

  def claim!(actor:)
    with_lock do
      next false if claimed_by == actor
      raise ClaimedByOther, self if claimed_by

      update!(claimed_by: actor, claimed_at: Time.current)
      record_event!("story.claimed", actor: actor, story: self)
    end
  end

  def release!(actor:, reason: nil)
    with_lock do
      next false unless claimed_by

      from = claimed_by.name
      update!(claimed_by: nil, claimed_at: nil)
      record_event!("story.released", actor: actor, story: self, data: { from: from }, reason: reason)
    end
  end

  # Reordena dentro de su hito o la mueve a otro (o a la bandeja, con
  # `milestone: nil`). `position` admite lo mismo que la gema positioning.
  # Los agentes tienen que dar un motivo.
  def reorder!(position:, actor:, milestone: self.milestone, reason: nil)
    require_reason!(actor, reason)

    transaction do
      from = { milestone_id: milestone_id, position: self.position }
      update!(milestone: milestone, position: position)
      reload
      to = { milestone_id: milestone_id, position: self.position }
      next false if to == from

      action = to[:milestone_id] == from[:milestone_id] ? "story.reordered" : "story.moved"
      record_event!(action, actor: actor, story: self, data: { from: from, to: to }, reason: reason)
    end
  end

  def add_comment!(body, actor:)
    transaction do
      comments.create!(body: body, actor: actor).tap do
        record_event!("comment.added", actor: actor, story: self)
      end
    end
  end

  # Pregunta con sus opciones y la recomendación (`mt ask`). Si bloquea y la
  # historia era del que pregunta, la suelta antes: vuelve a Lista y ya no la
  # coge nadie hasta que se conteste. Una no bloqueante no la suelta.
  def ask!(attributes, actor:)
    transaction do
      question = questions.build(attributes.to_h.symbolize_keys.merge(actor: actor))
      question.validate!
      move_to!(:ready, actor: actor) if question.blocking? && in_progress? && claimed_by == actor
      question.save!
      record_event!("question.asked", actor: actor, story: self,
        data: { question_id: question.id, title: question.title, blocking: question.blocking?, recommended: question.recommended }.compact)
      question
    end
  end

  # Responde con el número de una opción o, sin ella, con un texto libre en
  # `note` (MT-30). Con `decide`, queda además como decisión
  # de la historia (D-n). Devuelve la pregunta.
  def answer_question!(question, option: nil, note: nil, actor:, decide: false)
    question.with_lock do
      question.answer!(option: option, note: note, actor: actor)
      decision = project.record_decision!({ title: "#{question.title} → #{question.answer_text.truncate(80)}", body: question.answer_note.to_s, story: self }, actor: actor) if decide
      record_event!("question.answered", actor: actor, story: self,
        data: { question_id: question.id, option: question.answer, answer: question.answer_text, asked_by: question.actor.name, decision: decision&.number }.compact)
      question
    end
  end
end
