# encoding: utf-8

class Item < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :sprint, optional: true
  belongs_to :project

  enum :status, { unstarted: 0, started: 1, finished: 2, delivered: 3, accepted: 4, rejected: 5 }, default: :unstarted
  enum kind: { bug: 0, feature: 1, chore: 2, release: 3 }

  scope :on_backlog, -> { where.not(status: :accepted).where(backlog: 1) }
  scope :on_icebox, -> { where(icebox: 1) }
  scope :in_progress, -> { where(in_progress: 1) }
  scope :done, -> { where(done: 1) }

  before_save :set_accepted_at, if: -> { status_changed? && status == "accepted" }
  before_save :set_started_at, if: -> { status_changed? && status == "started" }

  positioned on: [ :project, :done, :in_progress, :icebox ]

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

  def set_started_at
    self.started_at = Time.zone.now
  end
end
