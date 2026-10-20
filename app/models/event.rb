# Un hecho: quién hizo qué y cuándo. Solo se añaden; no se editan ni se borran.
# `action` es texto libre a propósito: en M4 llegarán acciones de herramientas
# externas que el núcleo no interpreta.
class Event < ApplicationRecord
  belongs_to :project
  belongs_to :story, optional: true
  belongs_to :actor

  attribute :occurred_at, default: -> { Time.current }

  scope :recent_first, -> { order(occurred_at: :desc, id: :desc) }

  validates :action, presence: true

  # Cada escritura se emite en directo (MT-36) para el proyecto y la portada; si
  # la hizo el actor de una petición de la API, además lo marca «escribiendo».
  # No es un callback de dominio: no cambia datos, solo avisa.
  after_create_commit :broadcast_write

  def readonly? = persisted? || super

  private

  def broadcast_write
    locals = { event: self }
    Turbo::StreamsChannel.broadcast_append_to([ project, :writes ], target: "writes", partial: "presences/write", locals: locals)
    Turbo::StreamsChannel.broadcast_append_to(:writes, target: "writes", partial: "presences/write", locals: locals)
    Presence.wrote(self) if Current.actor == actor && actor.agent?
  rescue => e
    Rails.error.report(e, handled: true) # emitir no puede romper la escritura ya hecha
  end
end
