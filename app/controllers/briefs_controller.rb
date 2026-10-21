# Brief (5.5): la visión del proyecto en markdown y sus decisiones.
class BriefsController < ApplicationController
  include ProjectScoped

  before_action :set_decisions, only: %i[show edit update]

  def show
  end

  def edit
  end

  # Con la versión del brief que abrió el formulario (MT-37): si cambió
  # entretanto no se guarda y se enseña qué cambió.
  def update
    @form_version = params[:version]
    return resolve_conflict(Project.find(@project.id)) if params[:resolve] == "bring"

    @project.edit_brief!(params.expect(project: [ :brief ])[:brief], actor: Current.actor, version: @form_version)
    redirect_to project_brief_path(@project)
  rescue Versioned::Conflict => e
    resolve_conflict(Project.find(@project.id), editor: e.editor, edited_at: e.edited_at)
  rescue ActiveRecord::RecordInvalid
    render :edit, status: :unprocessable_entity
  end

  private

  def resolve_conflict(theirs, editor: nil, edited_at: nil)
    editor, edited_at = theirs.last_editor if editor.nil?
    mine = params.expect(project: [ :brief ])[:brief].to_s.gsub("\r\n", "\n").strip
    base = params[:base_brief].nil? ? theirs.brief.strip : params[:base_brief].to_s.gsub("\r\n", "\n").strip
    conflict = EditConflict.new(labels: { "brief" => "Brief" }, base: { "brief" => base }, mine: { "brief" => mine },
      theirs: { "brief" => theirs.brief.strip }, editor: editor, edited_at: edited_at)

    if params[:resolve] == "bring"
      @project.brief = conflict.merged["brief"]
      @form_version = theirs.brief_version
      @base_brief = theirs.brief.strip
      @notice = "Los dos habéis cambiado el brief: se ha quedado lo tuyo." if conflict.clashes.any?
      render :edit, status: :unprocessable_entity # Turbo solo pinta respuestas de formulario con 4xx
    else
      @project.brief = params.expect(project: [ :brief ])[:brief]
      @conflict = conflict
      render :edit, status: :conflict
    end
  end

  def set_decisions
    @decisions = @project.decisions.reorder(number: :desc).includes(:actor, :story, :supersedes, :superseded_by)
    @last_edit = @project.events.where(action: "brief.edited").maximum(:occurred_at)
  end
end
