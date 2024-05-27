module ItemsHelper
  def item_kind_options
    Item.kinds.map { |key, _value| [ Item.format_kind(key.to_sym), key ] }
  end

  def item_button_caption(item)
    case item.status
    when "unstarted"
      "Start"
    when "started"
      "Finish"
    when "finished"
      "Deliver"
    when "delivered"
      "Accept"
    when "accepted"
      "Reject"
    when "rejected"
      "Restart"
    end
  end
end
