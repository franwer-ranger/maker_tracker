class Project < ApplicationRecord
  has_many :items, dependent: :destroy
  has_many :sprints, dependent: :destroy

  def recreate_sprints
    sprints.destroy_all
    weeks.each_slice(sprint_length).with_index do |sprint_iteration, i|
      sprint_iteration = sprint_iteration.flatten
      sprint = sprints.find_or_initialize_by(start_date: sprint_iteration.first)
      sprint.end_date = sprint_iteration.last
      sprint.length = sprint_length
      sprint.number = i + 1
      sprint.save!
    end
  end

  def previous_sprints
    sprints[0..-2]
  end

  private

  def weeks
    (start_date..current_sprint_end_date).to_a.in_groups_of(7)
  end

  def current_sprint_end_date
    sprint_days = ((sprint_length * 7) - 1).days
    Date.today + sprint_days - (relative_cwdays[Date.today.cwday] - 1)
  end

  def current_week_end_date
    Date.today + 6.days - (relative_cwdays[Date.today.cwday] - 1)
  end

  def relative_cwdays
    cwdays = (start_date..(start_date + 6.days)).to_a.map { |day| day.cwday }
    cwdays.each_with_index.reduce({}) { |result, (cwday, i)| result[cwday] = i + 1; result }
  end
end
