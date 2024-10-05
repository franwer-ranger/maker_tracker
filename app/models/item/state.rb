module Item::State extend ActiveSupport::Concern
  def state_change(new_state, user = nil)
    case new_state
    when "unstarted"
      user ? self.start(user) : self.to_icebox
    when "started"
      self.finish
    when "finished"
      self.deliver
    when "accepted"
      self.accepted
    when "to_backlog"
      self.to_backlog
    when "to_icebox"
      self.to_icebox
    end
  end

  def start(user)
    update(
      user: user,
      status: "started",
      sprint: project.current_sprint,
      in_progress: true,
      icebox: false,
      done: false, backlog: false, position: nil
    )
  end

  def finish
    update(
      status: "finished",
      in_progress: true,
      icebox: false,
      done: false,
      backlog: false
    )
  end

  def deliver
    update(
      status: "delivered",
      in_progress: true,
      icebox: false,
      done: false,
      backlog: false
    )
  end

  def accepted
    update(
      status: "accepted",
      in_progress: false,
      icebox: false,
      done: true,
      backlog: false
    )
  end

  def to_backlog
    update(
      sprint_id: nil,
      backlog: true,
      done: false,
      in_progress: false,
      icebox: false
    )
  end

  def to_icebox
    update(
      sprint_id: nil,
      status: "unstarted",
      icebox: true,
      backlog: false,
      done: false,
      in_progress: false
    )
  end
end
