# Tablero (5.1): las historias de un hito en columnas por estado.
# Filtro en ?hito=: el número de un hito (2), "ideas" o "todos".
class BoardsController < ApplicationController
  include ProjectScoped

  RECENT_DONE = 10

  def show
    set_filter
    stories = filtered_stories.includes(:claimed_by, :milestone).to_a
    @columns = Story::STATE_NAMES.keys.index_with { |state| stories.select { it.state == state } }
    limit_done_column if @filter == :all && params[:hechas] != "todas"
    @context = { next_story: @project.next_story, done_numbers: @project.stories.done.pluck(:number) }
  end

  private

  def set_filter
    @milestones = @project.milestones.to_a
    case params[:hito]
    when "ideas" then @filter = :ideas
    when "todos" then @filter = :all
    else
      @milestone = @milestones.find { it.position.to_s == params[:hito] } || @project.current_milestone
      @filter = @milestone ? :milestone : :ideas
    end
  end

  def filtered_stories
    case @filter
    when :milestone then @milestone.stories
    when :ideas then @project.ideas
    else
      # Primero el orden de los hitos; la bandeja, al final.
      @project.stories.left_joins(:milestone)
        .order(Arel.sql("milestones.position IS NULL, milestones.position, stories.position"))
    end
  end

  def limit_done_column
    done = @columns["done"]
    @hidden_done = [ done.size - RECENT_DONE, 0 ].max
    @columns["done"] = done.sort_by(&:updated_at).last(RECENT_DONE).reverse
  end
end
