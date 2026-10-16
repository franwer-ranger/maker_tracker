class StoriesController < ApplicationController
  include ProjectScoped

  def show
    @story = @project.stories.find_by!(number: params[:number])
  end
end
