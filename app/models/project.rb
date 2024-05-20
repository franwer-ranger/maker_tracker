class Project < ApplicationRecord
  has_many :items, dependent: :destroy
end
