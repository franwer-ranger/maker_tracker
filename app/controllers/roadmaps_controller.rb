# Roadmap (5.3): los hitos en orden con sus historias; la bandeja al final.
class RoadmapsController < ApplicationController
  include ProjectScoped

  def show
    @milestones = @project.milestones.includes(stories: %i[claimed_by questions]).to_a
    @open_milestone = @milestones.find { !it.closed? }
    @ideas = @project.ideas.includes(:claimed_by, :questions).to_a
    @context = { next_story: @project.next_story, done_numbers: @project.stories.done.pluck(:number) }
  end
end
