# Conversación en una historia. En M1 no se editan ni se borran.
class Comment < ApplicationRecord
  belongs_to :story
  belongs_to :actor

  validates :body, presence: true

  def readonly? = persisted? || super
end
