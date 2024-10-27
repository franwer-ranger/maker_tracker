# encoding: utf-8

class CommentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_comment, only: %i[edit update destroy]
  before_action :set_item, only: %i[create update edit destroy]
  before_action :set_project, only: %i[create update edit destroy]

  def edit
  end


  def create
    @comment = @item.comments.new(comment_params.merge(user: current_user))
    if @comment.save
      redirect_to edit_project_item_url(@item, project_id: @item.project.id), notice: "Comment was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @comment.update(comment_params)
      redirect_to edit_project_item_url(@comment.item, project_id: @comment.item.project.id), notice: "Comment was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    project_id = @comment.item.project.id
    @comment.destroy!
    redirect_to edit_project_item_url(@comment.item, project_id: project_id), notice: "Comment was successfully updated."
  end

  private

  def set_comment
    @comment = Comment.find(params[:id])
  end

  def set_project
    @project = Project.find(params[:project_id])
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_item
    @item = Item.find(params[:item_id])
  end

  # Only allow a list of trusted parameters through.
  def comment_params
    params.require(:comment).permit(:content)
  end
end
