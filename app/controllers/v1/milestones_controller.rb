# Editar el título y el objetivo de un hito (MT-99): las validaciones y el
# conflicto de versión de Rails vuelven al formulario como `errors` de Inertia.
module V1
  class MilestonesController < ApplicationController
    before_action :set_milestone

    def edit
      render inertia: "MilestoneEdit", props: {
        milestone: { code: @milestone.code, title: @milestone.title, goal: @milestone.goal.to_s, version: @milestone.version,
                     url: project_v1_milestone_path(@project, @milestone.number) }
      }
    end

    def update
      changed = @milestone.edit!(params.expect(milestone: %i[title goal]), actor: Current.actor, version: params.dig(:milestone, :version))
      redirect_to project_v1_cover_path(@project), notice: changed ? "#{@milestone.code} guardado" : "#{@milestone.code} sin cambios"
    rescue ActiveRecord::RecordInvalid => e
      redirect_to edit_project_v1_milestone_path(@project, @milestone.number), inertia: { errors: e.record.errors.to_hash }
    rescue Versioned::Conflict => e
      editor = e.editor&.name || "alguien"
      redirect_to edit_project_v1_milestone_path(@project, @milestone.number),
        inertia: { errors: { base: [ "#{editor} cambió #{@milestone.code} mientras lo editabas. Recarga para ver su versión." ] } }
    end

    private

    def set_milestone
      @milestone = @project.milestones.find_by!(number: params[:number])
    end
  end
end
