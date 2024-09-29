module Project::Backlog extend ActiveSupport::Concern
  def backlog
    current_velocity = in_progress_velocity || 0
    current_sprint_number = sprints.last.number + 1

    current_backlog = []

    items.on_backlog.order(:position).each do |item|
      current_velocity = current_velocity + (item.points || 0)

      if current_velocity > velocity_with_override

        current_backlog << {
          type: "sprint",
          value: Sprint.build_by_number(self, current_sprint_number)
        }
        current_velocity = item.points || 0
        current_sprint_number += 1
      end

      current_backlog << { type: "item", value: item }
    end

    current_backlog
  end
end
