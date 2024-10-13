# encoding: utf-8

class CommentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_item, only: %i[create update destroy]
  before_action :set_project, only: %i[create]

  def create
    @comment = Comment.new(comment_params)
    @comment.item = @item
    @comment.user = current_user

    if @comment.save!
      redirect_to @project, notice: "Comment was successfully created."
    end
  end

  def update
    if @comment.update(comment_params)
      redirect_to @project, notice: "Comment was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @comment.destroy!

    respond_to do |format|
      format.html { redirect_to items_url, notice: "Item was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_item
    @item = Item.find(params[:item_id])
  end

  # Only allow a list of trusted parameters through.
  def comment_params
    params.require(:comment).permit(:content, :item_id, :user_id)
  end
end
