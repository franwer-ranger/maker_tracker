class Item < ApplicationRecord
  belongs_to :user
  belongs_to :sprint
  belongs_to :project

  enum status: { unstarted: 0, started: 1, finished: 2, delivered: 3, accepted: 4, rejected: 5 }
  enum kind: { bug: 0, feature: 1, chore: 2, release: 3 }

  scope :on_backlog, -> { where.not(status: :accepted).where(icebox: 0) }
  scope :on_icebox, -> { where(icebox: 1) }

  def self.format_kind(kind)
    kind_formatted[kind]
  end

  def self.kind_formatted
    { bug: "🐞 Bug", feature: "💫 Feature", chore: "⚙️ Chore", release: "🚀 Release" }
  end
end
