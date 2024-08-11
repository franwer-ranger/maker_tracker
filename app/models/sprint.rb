class Sprint < ApplicationRecord
  belongs_to :project
  has_many :items, dependent: :nullify

  def items_by_accepted_at
    Item.accepted.where(accepted_at: start_date.beginning_of_day..end_date.end_of_day)
  end
end
