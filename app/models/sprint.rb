class Sprint < ApplicationRecord
  belongs_to :project
  has_many :items, dependent: :nullify

  def self.build_by_number(project, number)
    start_date = (project.start_date + (number - 1) * project.sprint_length.weeks).beginning_of_day
    end_date = (start_date + project.sprint_length.weeks - 1.day).end_of_day
    Sprint.new(
      project: project,
      start_date: start_date,
      end_date: end_date,
      number: number
    )
  end

  def past?
    end_date < Sprint.last.start_date
  end

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
