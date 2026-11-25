# Editar una historia (MT-112, «v1 · 9 · Editar»): el título, las propiedades
# (hito, capacidades, etiquetas y mockup) y las secciones de la plantilla
# (MT-52), con lo que le falta para Lista y el contraste con lo decidido
# (`mt check`, MT-79) mientras se escribe. El cuerpo se parte y se vuelve a
# juntar en el navegador; aquí llega entero, como lo guarda `mt edit`.
# Si la historia cambió mientras se editaba, no se guarda: vuelve un aviso
# (el conflicto lado a lado es MT-117).
module V1
  class StoryEditsController < ApplicationController
    CONTRAST = 3
    CONTRAST_TEXT = 4_000

    before_action :set_story

    def edit
      render inertia: "StoryEdit", props: { story: story_props, milestones: milestones, capabilities: capabilities, guides: guides }
    end

    # El hito solo llega si se cambió en el formulario: si no, guardar no deshace un movimiento hecho mientras
    # tanto (mover no sube la versión). El contenido y el hito, en una sola transacción.
    def update
      attributes = params.expect(story: [ :title, :body, :mockup, :labels, { capabilities: [] } ])
      move = params[:story].key?(:milestone_id)
      milestone = chosen_milestone if move
      return redirect_to project_v1_story_edit_path(@project, @story.number), inertia: { errors: { milestone_id: [ "Ese hito no es de este proyecto." ] } } if milestone == false

      changed = Story.transaction do
        edited = @story.edit!(attributes, actor: Current.actor, version: params.dig(:story, :version))
        moved = move && milestone != @story.milestone && @story.reorder!(position: :last, milestone: milestone, actor: Current.actor)
        edited || moved
      end
      redirect_to project_v1_story_path(@project, @story.number), notice: changed ? "#{@story.reference} guardada" : "#{@story.reference} sin cambios"
    rescue ActiveRecord::RecordInvalid => e
      redirect_to project_v1_story_edit_path(@project, @story.number), inertia: { errors: e.record.errors.to_hash }
    rescue Versioned::Conflict => e
      editor = e.editor&.name || "Alguien"
      redirect_to project_v1_story_edit_path(@project, @story.number),
        inertia: { errors: { base: [ "#{editor} cambió #{@story.reference} mientras la editabas. No se ha guardado nada: copia lo tuyo y recarga para ver su versión." ] } }
    end

    # «Contrasta con lo decidido»: `mt check` con lo que se está escribiendo (título, contexto e
    # historia). Solo lee; las decisiones y el brief primero, y nunca la propia historia.
    def contrast
      check = ProposalCheck.new(@project, params[:text].to_s.first(CONTRAST_TEXT))
      results = check.results.reject { it.document.record == @story }.sort_by { it.document.kind == :story ? 1 : 0 }
      render json: { results: results.first(CONTRAST).map { contrast_item(it) } }
    end

    private

    def set_story
      @story = @project.stories.find_by!(number: params[:number])
    end

    # Vacío: a la bandeja. Uno que no es del proyecto: false, para que dé error en vez de mandarla a la bandeja.
    def chosen_milestone
      id = params.dig(:story, :milestone_id)
      id.blank? ? nil : @project.milestones.find_by(id: id) || false
    end

    def story_props
      {
        ref: @story.reference,
        number: @story.number,
        title: @story.title,
        state: @story.state,
        body: @story.body.to_s,
        milestone_id: @story.milestone_id,
        capabilities: Array(@story.capabilities),
        labels: Array(@story.labels).join(", "),
        mockup: @story.mockup.to_s,
        version: @story.version,
        open_questions: @story.open_questions_asked.size,
        url: project_v1_story_edit_path(@project, @story.number),
        contrast_url: project_v1_story_contrast_path(@project, @story.number),
        show_url: project_v1_story_path(@project, @story.number),
        copy: Api::Markdown::Story.new(@story).to_s
      }
    end

    # Los hitos abiertos, en orden del roadmap, y el suyo aunque esté cerrado.
    def milestones
      @project.milestones.where(closed_at: nil).or(@project.milestones.where(id: @story.milestone_id)).order(:position)
        .map { { id: it.id, label: [ it.code, it.title ].join(" · ") } }
    end

    def capabilities = @project.pages.documentation.ordered.map { { slug: it.slug, title: it.title } }

    # La guía de cada sección, de los comentarios de la plantilla (MT-52).
    def guides
      Story::BODY_TEMPLATE.scan(/^## (.+)\n(?:<!--\s*(.*?)\s*-->)?/).map { |heading, guide| { heading: heading.strip, guide: guide } }
    end

    def contrast_item(result)
      doc = result.document
      case doc.kind
      when :decision
        { kind: "decision", reference: doc.record.reference, title: doc.record.title, excerpt: result.excerpt,
          url: project_v1_decision_path(@project, doc.record.number) }
      when :story
        { kind: "story", reference: doc.record.reference, title: doc.record.title, excerpt: result.excerpt&.gsub(/#+\s*/, ""),
          url: project_v1_story_path(@project, doc.record.number) }
      else
        { kind: "brief", reference: "Brief", title: doc.section.presence || "Brief", excerpt: doc.body.truncate(160), url: nil }
      end
    end
  end
end
