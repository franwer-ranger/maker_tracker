module ItemsHelper
  def item_kind_options
    Item.kinds.map { |key, _value| [Item.format_kind(key.to_sym), key] }
  end
end
