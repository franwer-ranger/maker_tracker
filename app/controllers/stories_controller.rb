class StoriesController < ApplicationController
  include ProjectScoped

  before_action :set_story, only: %i[show edit update]

  # Abrir la historia es mirarla (MT-31): se marca la visita y arriba se enseña
  # lo cambiado desde la anterior.
  def show
    now = Time.current
    @since = Visit.open!(@story, now: now)
    @changes = WhileAway.story(@story, since: @since, now: now) if @since
  end

  def edit
  end

  # Título, cuerpo y propiedades, con Story#edit! (deja story.edited). El
  # formulario manda la versión que abrió: si la historia cambió entretanto
  # no se guarda y se enseña qué cambió, sin perder lo escrito (MT-37).
  def update
    @form_version = params[:version]
    @base = base_values
    return resolve_conflict(Story.find(@story.id)) if params[:resolve] == "bring"

    @story.edit!(story_params, actor: Current.actor, version: @form_version)
    redirect_to project_story_path(@project, @story)
  rescue Versioned::Conflict => e
    resolve_conflict(Story.find(@story.id), editor: e.editor, edited_at: e.edited_at)
  rescue ActiveRecord::RecordInvalid
    render :edit, status: :unprocessable_entity
  end

  # "+ Nueva idea" del Tablero y del Roadmap: solo el título, en el hito o en la bandeja.
  def create
    milestone = @project.milestones.find_by(id: params.dig(:story, :milestone_id))
    @project.create_story!({ title: params.expect(story: [ :title ])[:title], milestone: milestone }, actor: Current.actor)
    redirect_back_or_to project_path(@project)
  rescue ActiveRecord::RecordInvalid => e
    redirect_back_or_to project_path(@project), alert: e.record.errors.full_messages.join(". ")
  end

  private

  def set_story
    @story = @project.stories.find_by!(number: params[:number])
  end

  FIELD_LABELS = { "title" => "Título", "body" => "Cuerpo", "mockup" => "Mockup", "labels" => "Labels", "blocked_by" => "Bloqueada por" }.freeze

  # Lo que escribió quien edita, en el formato del formulario.
  def mine_values = story_params.to_h.then { |values| FIELD_LABELS.keys.index_with { |field| normalize(field, values[field]) } }

  # Lo que había al abrir el formulario (campos ocultos base_*).
  def base_values = FIELD_LABELS.keys.index_with { |field| params["base_#{field}"].nil? ? nil : normalize(field, params["base_#{field}"]) }

  def current_values(story) = FIELD_LABELS.keys.index_with { |field| normalize(field, story.public_send(field)) }

  def normalize(field, value)
    case field
    when "labels", "blocked_by" then (value.is_a?(Array) ? value : value.to_s.split(field == "labels" ? "," : /[\s,]+/)).map { it.to_s.strip }.compact_blank.join(", ")
    else value.to_s.gsub("\r\n", "\n").strip
    end
  end

  # La historia cambió: «Traer sus cambios» sigue con lo de los dos; si no,
  # enseña el aviso con lo escrito intacto y la versión vieja en el formulario.
  def resolve_conflict(theirs, editor: nil, edited_at: nil)
    theirs_values = current_values(theirs)
    base = @base.compact.presence ? theirs_values.merge(@base.compact) : theirs_values
    editor, edited_at = theirs.last_editor if editor.nil?
    conflict = EditConflict.new(labels: FIELD_LABELS, base: base, mine: mine_values, theirs: theirs_values, editor: editor, edited_at: edited_at)

    if params[:resolve] == "bring"
      @story.assign_attributes(conflict.merged)
      @form_version = theirs.version
      @base = theirs_values
      @notice = ("Los dos habéis cambiado (#{conflict.clashes.map { FIELD_LABELS[it].downcase }.join(', ')}): se ha quedado lo tuyo." if conflict.clashes.any?)
      render :edit, status: :unprocessable_entity # Turbo solo pinta respuestas de formulario con 4xx
    else
      @story.assign_attributes(story_params)
      @conflict = conflict
      render :edit, status: :conflict
    end
  end

  def story_params
    params.expect(story: %i[title body mockup labels blocked_by])
  end
end
