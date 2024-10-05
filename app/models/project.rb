class Project < ApplicationRecord
  include Backlog

  has_many :items, dependent: :destroy
  has_many :sprints, dependent: :destroy
  after_create :recreate_sprints

  def in_progress_will_release?
    in_progress_velocity >= velocity_with_override
  end

  def in_progress_velocity
    current_sprint.current_velocity +
      current_sprint.in_progress.reduce(0) { |sum, item| sum + item.points }
  end

  def velocity_overrided?
    velocity_override.present?
  end

  def velocity_with_override
    velocity_override || velocity
  end

  def recreate_sprints
    sprints.destroy_all

    sprint_start_date = start_date

    sprint_number = 0
    loop do
      sprint_number += 1
      sprint_end_date = ((sprint_start_date + sprint_length.weeks) - 1.day).end_of_day
      recreate_sprint(sprint_number, sprint_start_date, sprint_end_date)
      sprint_start_date = (sprint_end_date + 1.day).beginning_of_day
      break if sprint_end_date > Date.today
     end
     recreate_velocity
  end

  def previous_sprints
    sprints[0..-2]
  end

  def current_sprint
    sprints.last
  end

  private

  def recreate_velocity
    velocity_window = 3
    sprints = Sprint.last(velocity_window + 1).first(velocity_window)
    new_velocity = sprints.map(&:current_velocity).sum / velocity_window
    update velocity: new_velocity
    new_velocity
  end

  def recreate_sprint(number, start_date, end_date)
    sprint = sprints.find_or_initialize_by(start_date: start_date)
    sprint.end_date = end_date
    sprint.length = sprint_length
    sprint.number = number
    sprint.save!
  end
end
