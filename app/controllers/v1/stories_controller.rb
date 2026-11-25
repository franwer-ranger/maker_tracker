# Una historia (MT-104, «v1 · 4 · Historia»): leída como un documento. Estado
# e hito, el título, la historia en una frase, la pregunta abierta, qué cambia
# del producto, criterios, fuera de alcance y el resto plegado; al lado
# pantallas, las decisiones que la rigen y la actividad. Sin QA (D-97) ni
# estado «En curso»: en curso es Lista con la marca «en construcción». En
# directo como la capacidad: cada evento del proyecto repinta `story`.
module V1
  class StoriesController < ApplicationController
    ACTIVITY = 6
    OWN_ACTIONS = %w[story.created story.state_changed story.edited story.claimed story.released story.documented
                     question.asked question.answered comment.added attachment.added].freeze

    before_action :set_story

    def show
      render inertia: "Story", props: { story: InertiaRails.live(@project) { story_props } }
    end

    # «Marcar como Lista»: solo de Definiendo y si ya no le falta nada (como en el taller).
    def ready
      return back("#{@story.reference} ya no está pendiente de tu OK") unless @story.reviewable?

      @story.move_to!("ready", actor: Current.actor)
      back("#{@story.reference} está Lista para construir")
    rescue Story::ClaimedByOther => e
      back(e.message)
    end

    def answer
      question = @story.questions.find(params[:question_id])
      @story.answer_question!(question, option: Integer(params[:option].to_s), note: nil, actor: Current.actor)
      back("Respondiste a #{question.actor.name}: «#{question.answer_text.truncate(80)}»")
    rescue Question::AlreadyAnswered
      back("Esa pregunta ya estaba respondida.")
    rescue ArgumentError, ActiveRecord::RecordInvalid
      back("Elige una de las opciones.")
    end

    def comment
      @story.add_comment!(params[:body].to_s, actor: Current.actor)
      redirect_to project_v1_story_path(@project, @story.number, anchor: "comentarios")
    rescue ActiveRecord::RecordInvalid
      back("Escribe algo para comentar.")
    end

    # «Enlazar» la capacidad candidata de una Hecha que se cerró sin decir cuáles cambia. Solo
    # entonces, y leyendo las capacidades bajo el bloqueo. La página sigue pendiente hasta que se edite.
    def link_capability
      page = @project.pages.documentation.find_by!(slug: params[:slug])
      linked = @story.with_lock do
        next false unless @story.closed_without_capabilities?

        @story.edit!({ capabilities: [ *@story.capabilities, page.slug ].uniq }, actor: Current.actor)
      end
      return back("#{@story.reference} ya no tiene la documentación pendiente") unless linked

      back("#{@story.reference} cambia «#{page.title}». Falta que la página lo cuente.")
    end

    private

    def set_story
      @story = @project.stories.find_by!(number: params[:number])
    end

    def back(notice) = redirect_to(project_v1_story_path(@project, @story.number), notice: notice)

    def story_props
      story = @project.stories.includes(:milestone, :claimed_by, questions: :actor).find(@story.id)
      reading = Story::Reading.new(story)
      {
        ref: story.reference,
        number: story.number,
        title: story.title,
        state: story.in_progress? ? "ready" : story.state,
        milestone: story.milestone && [ story.milestone.code, story.milestone.title ].join(" · "),
        building: building(story),
        closed: closed(story),
        sentence: reading.sentence,
        question: open_question(story),
        ready_url: (project_v1_story_ready_path(@project, story.number) if story.defining?),
        ready_blockers: ready_blockers(story),
        changes: reading.changes.map { it.except(:slug).merge(url: project_v1_capability_path(@project, it[:slug])) },
        changes_text: reading.changes_text,
        documentation: documentation(story),
        criteria: reading.criteria,
        out_of_scope: reading.out_of_scope,
        context: reading.context,
        screens: screens(story),
        decisions: story.related_decisions.map do
          { reference: it.reference, title: it.title, superseded: it.superseded_by&.reference, url: project_brief_path(@project, anchor: it.reference) }
        end,
        activity: activity(story),
        events: story.events.count,
        comments: story.comments.includes(:actor).map { comment_props(it) },
        copy: Api::Markdown::Story.new(story).to_s,
        edit_url: edit_project_story_path(@project, story),
        history_url: project_story_path(@project, story),
        comment_url: project_v1_story_comment_path(@project, story.number)
      }
    end

    # «en construcción · claude · desde 23:46»: quién la tiene y desde cuándo.
    def building(story)
      return unless story.in_progress? || (story.ready? && story.claimed_by)

      { agent: story.claimed_by&.name, since: story.claimed_at&.iso8601 }
    end

    # Hecha: cuándo y con qué commits.
    def closed(story)
      return unless story.done?

      close = story.last_close
      { at: close&.occurred_at&.iso8601, commits: close ? close.commits.map(&:short) : [] }
    end

    # La pregunta abierta de arriba: la bloqueante, si hay.
    def open_question(story)
      question = story.open_questions_asked.max_by { it.blocking? ? 1 : 0 } or return
      question_props(question, answer_url: project_v1_story_answer_path(@project, story.number))
    end

    def ready_blockers(story)
      return [] unless story.defining?

      [ ("Aún no tiene criterios de aceptación." unless story.criteria?), *story.readiness_issues ].compact
    end

    # Hecha con la documentación pendiente (MT-91): o se cerró sin decir qué capacidades cambia (con la
    # que más encaja para enlazarla), o sin actualizar las páginas de las que sí dijo, o se enlazaron
    # después del cierre («Enlazar») y aún no se han editado.
    def documentation(story)
      if story.closed_without_capabilities?
        candidate = candidate_capability(story)
        { kind: "unlinked", prompt: documentation_prompt(story, relink: false),
          candidate: candidate && { title: candidate.title, icon: candidate.icon, area: candidate.area,
                                    link_url: project_v1_story_capability_path(@project, story.number, slug: candidate.slug) } }
      else
        pending = story.pending_documentation
        pages = pending | story.linked_after_close_undocumented
        return if pages.empty?

        { kind: "outdated", prompt: documentation_prompt(story, relink: pending.any?), relink: pending.any?,
          pages: pages.map { { title: it.title, icon: it.icon, url: project_v1_capability_path(@project, it.slug) } } }
      end
    end

    # El paso 4 solo si hay pendientes del cierre: `mt done` enlaza esas; las enlazadas después basta con editarlas.
    def documentation_prompt(story, relink:)
      steps = [
        "Léela con `mt show #{story.reference}` y la documentación con `mt doc`.",
        "Si no dice qué capacidades cambia, añádelas con `mt edit #{story.reference}` (propiedad `capabilities`).",
        "Actualiza cada página con `mt doc edit <slug> --file <f.md>` contando cómo queda.",
        ("Vuelve a hacer `mt done #{story.reference}` para enlazarlas al cierre." if relink)
      ].compact
      [ "Documenta #{story.reference} («#{story.title}») en #{@project.name}: ya está Hecha y las páginas del producto aún no lo cuentan.",
        *steps.each_with_index.map { |step, index| "#{index + 1}. #{step}" } ].join("\n")
    end

    # La página que más palabras comparte con el título y la frase de la historia (el título pesa más).
    def candidate_capability(story)
      words = ->(text) { text.to_s.downcase.scan(/[[:alpha:]]{4,}/).to_set }
      wanted = words.(story.title) | words.(Story::Reading.new(story).sentence)
      scored = @project.pages.documentation.ordered.map { [ it, (words.(it.title) & wanted).size * 3 + (words.(it.body) & wanted).size ] }
      best, score = scored.max_by { it[1] }
      best if score.to_i.positive?
    end

    # El mockup y los adjuntos; las imágenes en línea, el resto como enlace.
    def screens(story)
      items = []
      items << { code: "M", title: helpers.mockup_label(story.mockup), href: story.mockup, src: nil } if story.mockup.present?
      story.ordered_attachments.each_with_index do |file, index|
        image = Attachable::INLINE_IMAGE_TYPES.include?(file.content_type)
        items << { code: "A#{index + 1}", title: file.filename.to_s, href: Attachable.path(file), src: (Attachable.path(file) if image) }
      end
      items
    end

    def activity(story)
      story.events.where(action: OWN_ACTIONS).includes(:actor).recent_first.limit(ACTIVITY).map do |event|
        { actor: event.actor.name, agent: event.actor.agent?, text: activity_text(event), at: event.occurred_at.iso8601 }
      end
    end

    def activity_text(event)
      data = event.data
      case event.action
      when "story.created" then "la creó en #{Story.human_state(data['state'] || 'idea')}"
      when "story.state_changed"
        case data["to"]
        when "in_progress" then "la empezó"
        when "done" then "la cerró"
        else "la pasó a #{Story.human_state(data['to'])}"
        end
      when "story.edited" then "editó la definición"
      when "story.claimed" then "la reclamó"
      when "story.released" then "la soltó"
      when "story.documented" then "actualizó la documentación"
      when "question.asked" then "dejó una pregunta abierta"
      when "question.answered" then "respondió la pregunta#{" → D-#{data['decision']}" if data['decision']}"
      when "comment.added" then "comentó"
      when "attachment.added" then "adjuntó #{data['filename']}"
      end
    end

    def comment_props(comment)
      { id: comment.id, actor: comment.actor.name, agent: comment.actor.agent?, at: comment.created_at.iso8601, blocks: comment_blocks(comment.body) }
    end

    # El comentario tal cual, en bloques: sus `##` como subtítulos.
    def comment_blocks(body)
      Page::Reading.new(body, plain: true).sections.flat_map { [ (it[:title] && { type: "heading", text: it[:title] }), *it[:blocks] ].compact }
    end
  end
end
