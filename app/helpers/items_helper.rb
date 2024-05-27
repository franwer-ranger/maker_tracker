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

  def item_button_styles(item)
    case item.status
    when "unstarted"
      "bg-gray-200 text-black"
    when "started"
      "bg-gray-800 text-white"
    when "finished"
      "bg-amber-500 text-black"
    when "delivered"
      ""
    when "accepted"
      ""
    when "rejected"
      ""
    end
  end
end
