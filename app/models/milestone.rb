# Un paso del roadmap. Su posición dentro del proyecto es su prioridad.
class Milestone < ApplicationRecord
  include Eventable
  include Versioned

  belongs_to :project
  has_many :stories, -> { order(:position) }, inverse_of: :milestone

  positioned on: :project

  scope :open, -> { where(closed_at: nil) }
  scope :closed, -> { where.not(closed_at: nil) }

  validates :title, presence: true

  def closed? = closed_at.present?

  # "M2": su número es su posición en el roadmap.
  def code = "M#{position}"

  # [hechas, total]
  def progress = [ stories.done.count, stories.count ]

  # Hecho si está cerrado; En curso si alguna historia ha empezado.
  def status
    return "Hecho" if closed?

    stories.in_progress.or(stories.done).exists? ? "En curso" : "Sin empezar"
  end

  # Operaciones de dominio: cada una hace su cambio y registra su evento.
  # Si no cambia nada, no hay evento y devuelven false.

  # Título y objetivo. El evento guarda qué campos cambiaron, como story.edited.
  # Con `version:` falla con Versioned::Conflict si el hito ya cambió.
  def edit!(attributes, actor:, version: nil)
    attributes = attributes.to_h.stringify_keys.slice("title", "goal")

    transaction do
      check_version!(version)
      assign_attributes(attributes)
      fields = changed & %w[title goal]
      next false if fields.empty?

      bump_version
      save!
      record_event!("milestone.edited", actor: actor, data: { milestone_id: id, fields: fields })
    end
  end

  def last_editor
    event = project.events.where(action: "milestone.edited").where("json_extract(data, '$.milestone_id') = ?", id)
      .reorder(occurred_at: :desc, id: :desc).includes(:actor).first
    [ event&.actor, event&.occurred_at ]
  end

  def close!(actor:)
    return false if closed?

    transaction do
      update!(closed_at: Time.current)
      record_event!("milestone.closed", actor: actor, data: { milestone_id: id })
    end
  end

  def reopen!(actor:)
    return false unless closed?

    transaction do
      update!(closed_at: nil)
      record_event!("milestone.reopened", actor: actor, data: { milestone_id: id })
    end
  end

  # `position` admite lo mismo que la gema positioning: un número, :first,
  # :last o { before: otro_hito } / { after: otro_hito }.
  def reorder!(position:, actor:, reason: nil)
    require_reason!(actor, reason)

    transaction do
      from = self.position
      update!(position: position)
      to = reload.position
      next false if to == from

      record_event!("milestone.reordered", actor: actor, data: { milestone_id: id, from: from, to: to }, reason: reason)
    end
  end
end
