# Un paso del roadmap. Su posición dentro del proyecto es su prioridad.
class Milestone < ApplicationRecord
  include Eventable

  belongs_to :project
  has_many :stories, -> { order(:position) }, inverse_of: :milestone

  positioned on: :project

  scope :open, -> { where(closed_at: nil) }
  scope :closed, -> { where.not(closed_at: nil) }

  validates :title, presence: true

  def closed? = closed_at.present?

  # Operaciones de dominio: cada una hace su cambio y registra su evento.
  # Si no cambia nada, no hay evento y devuelven false.

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
