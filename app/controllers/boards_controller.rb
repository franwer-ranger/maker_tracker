# El tablero antiguo (5.1) se sustituye por la Lista por hito de la v1 (MT-109):
# /p/:slug sigue funcionando y lleva allí.
class BoardsController < ApplicationController
  include ProjectScoped

  def show
    redirect_to project_v1_story_list_path(@project)
  end
end
