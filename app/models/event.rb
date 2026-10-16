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

  def readonly? = persisted? || super
end
