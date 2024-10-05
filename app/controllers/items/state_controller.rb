class Items::StateController < ApplicationController
  def update
    item = Item.find(params[:item_id])
    item.state_change(params[:state], current_user)
    redirect_to item.project
  end
end
