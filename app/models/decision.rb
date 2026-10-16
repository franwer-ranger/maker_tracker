# Qué decidimos y por qué. Solo se añaden: para cambiar una, se escribe otra
# que la sustituye (`supersedes`).
class Decision < ApplicationRecord
  include NumberedInProject

  belongs_to :project
  belongs_to :story, optional: true
  belongs_to :actor
  belongs_to :supersedes, class_name: "Decision", optional: true
  has_one :superseded_by, class_name: "Decision", foreign_key: :supersedes_id, inverse_of: :supersedes, dependent: nil

  validates :title, presence: true
  validate :story_and_supersedes_in_same_project

  def readonly? = persisted? || super

  def reference = "D-#{number}"

  private

  def story_and_supersedes_in_same_project
    errors.add(:story, "es de otro proyecto") if story && story.project_id != project_id
    errors.add(:supersedes, "es de otro proyecto") if supersedes && supersedes.project_id != project_id
  end
end
