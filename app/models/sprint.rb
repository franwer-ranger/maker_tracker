class Sprint < ApplicationRecord
  belongs_to :project
  has_many :items, dependent: :nullify

  def current?
    Sprint.last.id == id
  end

  def in_progress
    Item.in_progress.where(project: project)
  end

  def on_backlog
    Item.on_backlog.where(project: project)
  end

  def current_velocity
    items_by_accepted_at.sum(:points)
  end

  def items_by_accepted_at
    Item.accepted.where(accepted_at: start_date.beginning_of_day..end_date.end_of_day)
  end
end
