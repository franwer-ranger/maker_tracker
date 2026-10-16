# Quién hace algo: Fran o un agente (claude, codex…). Sin login, es la forma
# de saber quién hizo qué.
class Actor < ApplicationRecord
  HUMAN_NAME = "fran".freeze

  enum :kind, { human: "human", agent: "agent" }, validate: true

  has_many :decisions, dependent: :restrict_with_exception
  has_many :comments, dependent: :restrict_with_exception
  has_many :claimed_stories, class_name: "Story", foreign_key: :claimed_by_id, inverse_of: :claimed_by, dependent: :restrict_with_exception

  normalizes :name, with: -> { it.strip.downcase }

  validates :name, presence: true, uniqueness: true, format: { with: /\A[a-z0-9_-]+\z/, message: "solo admite minúsculas, números, - y _" }

  # El actor humano al que se atribuye todo lo que pasa en la UI (M1 tiene uno solo).
  def self.human
    human_kind.first || create_or_find_by!(name: HUMAN_NAME) { it.kind = :human }
  end

  scope :human_kind, -> { where(kind: :human).order(:id) }
end
