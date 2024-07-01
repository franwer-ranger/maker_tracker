# encoding: utf-8

class Item < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :sprint, optional: true
  belongs_to :project

  enum :status, { unstarted: 0, started: 1, finished: 2, delivered: 3, accepted: 4, rejected: 5 }, default: :unstarted
  enum kind: { bug: 0, feature: 1, chore: 2, release: 3 }

  scope :on_backlog, -> { where.not(status: :accepted).where(icebox: 0).where(sprint_id: nil) }
  scope :on_icebox, -> { where(icebox: 1) }
  scope :in_progress, -> { where(status: [ :started, :finished, :delivered ]) }

  before_save :set_accepted_at, if: -> { status_changed? && status == "accepted" }

  positioned on: [ :project, :sprint, :icebox ]

  def self.format_kind(kind)
    kind_formatted[kind]
  end

  def format_kind_icon
    Item.kind_icon[kind&.to_sym]
  end

  def self.kind_formatted
    { bug: "🐞 Bug", feature: "💫 Feature", chore: "⚙️ Chore", release: "🚀 Release" }
  end

  def self.kind_icon
    { bug: "🐞", feature: "💫", chore: "⚙️", release: "🚀" }
  end

  def set_accepted_at
    self.accepted_at = Time.zone.now
  end
end
