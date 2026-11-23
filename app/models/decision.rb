# Qué decidimos y por qué. Solo se añaden: para cambiar una, se escribe otra
# que la sustituye (`supersedes`). Rige las capacidades (páginas de la
# documentación) con las que se registró (MT-90).
class Decision < ApplicationRecord
  include NumberedInProject

  belongs_to :project
  belongs_to :story, optional: true
  belongs_to :actor
  belongs_to :supersedes, class_name: "Decision", optional: true
  has_one :superseded_by, class_name: "Decision", foreign_key: :supersedes_id, inverse_of: :supersedes, dependent: nil
  has_many :decision_capabilities, dependent: nil
  has_many :capabilities, through: :decision_capabilities, source: :page

  # Las que nadie ha sustituido.
  scope :in_force, -> { where.missing(:superseded_by) }

  validates :title, presence: true
  validate :story_and_supersedes_in_same_project
  validate :capabilities_are_documentation_of_project

  def readonly? = persisted? || super

  def reference = "D-#{number}"

  private

  def story_and_supersedes_in_same_project
    errors.add(:story, :other_project) if story && story.project_id != project_id
    errors.add(:supersedes, :other_project) if supersedes && supersedes.project_id != project_id
  end

  def capabilities_are_documentation_of_project
    errors.add(:capabilities, :other_project) if capabilities.any? { it.project_id != project_id }
    errors.add(:capabilities, :cover_not_capability) if capabilities.any?(&:cover?)
  end
end
