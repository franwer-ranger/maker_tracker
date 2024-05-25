module SprintsHelper
  def sprint_dates(sprint)
    result = if sprint.start_date.month == sprint.end_date.month
       "#{sprint.start_date.strftime('%B %d')} - #{sprint.end_date.strftime('%d')}"
    else
      "#{sprint.start_date.strftime('%B %d')} - #{sprint.end_date.strftime('%B %d')}"
    end

    result += ", #{sprint.start_date.year}" if sprint.start_date.year != Date.today.year
    result
  end
end
