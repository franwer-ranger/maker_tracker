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
    respond_to do |format|
      if @comment.save
        format.turbo_stream
        format.html { redirect_to edit_project_item_url(@item, project: @item.project), notice: "Comment was successfully created." }
        format.json { render :show, status: :created, location: @comment }
      else
        format.turbo_stream
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @comment.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    if @comment.update(comment_params)
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to @project, notice: "Comment was successfully updated." }
      end
      
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @comment.destroy!
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @project, notice: "Comment was successfully updated." }
      format.json { head :no_content }
    end
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
