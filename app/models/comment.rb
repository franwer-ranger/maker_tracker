class Comment < ApplicationRecord
  belongs_to :item
  belongs_to :user

  after_create_commit -> { broadcast_append_to "item_#{self.item_id}_comments", partial: "comments/comment", locals: { comment: self, item: self.item, project: self.item.project }, target: "item_#{self.item_id}_comments" }
  after_update_commit -> { broadcast_replace_to "item_#{self.item_id}_comments", partial: "comments/comment", locals: { comment: self, item: self.item, project: self.item.project } }
  after_destroy_commit -> { broadcast_remove_to "item_#{self.item_id}_comments", partial: "comments/comment", locals: { comment: self, item: self.item, project: self.item.project } }

  validates :content, presence: true
end
