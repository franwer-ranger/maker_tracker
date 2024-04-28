class Item < ApplicationRecord
  belongs_to :user
  belongs_to :sprint
  belongs_to :project

  enum status: { unstarted: 0, started: 1, finished: 2, delivered: 3, accepted: 4, rejected: 5 }
  enum kind: { bug: 0, feature: 1, chore: 2, release: 3 }
end
