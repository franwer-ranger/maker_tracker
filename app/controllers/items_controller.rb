# encoding: utf-8

class ItemsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_item, only: %i[show edit update destroy]
  before_action :set_project, only: %i[index edit new create]

  def index
    @items = Item.all
  end

  def show
  end

  def new
    @item = Item.new
    @users = User.all
  end

  def edit
    @users = User.all
  end

  def create
    @item = Item.new(item_params)
    @item.project = @project
    @item.position = 0

    if @item.save!
      redirect_to @project, notice: "Item was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    previous_status = @item.status
    if @item.update(item_params)
      @item.state_change(@item.status) if @item.status != previous_status
      redirect_to @item.project
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @item.destroy!

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
    @item = Item.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def item_params
    params.require(:item)
      .permit(:status, :kind, :icebox, :name, :description, :points, :position, :user_id, :sprint_id, :project_id, :accepted_at, :in_progress, :done, :backlog)
  end
end
