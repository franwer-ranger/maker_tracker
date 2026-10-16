# Un paso del roadmap. Su posición dentro del proyecto es su prioridad.
class Milestone < ApplicationRecord
  belongs_to :project
  has_many :stories, -> { order(:position) }, inverse_of: :milestone

  positioned on: :project

  scope :open, -> { where(closed_at: nil) }
  scope :closed, -> { where.not(closed_at: nil) }

  validates :title, presence: true

  def closed? = closed_at.present?

  def close!
    update!(closed_at: Time.current) unless closed?
  end

  def reopen!
    update!(closed_at: nil) if closed?
  end
end
