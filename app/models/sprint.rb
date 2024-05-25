class Sprint < ApplicationRecord
  belongs_to :project
  has_many :items, dependent: :destroy
end
