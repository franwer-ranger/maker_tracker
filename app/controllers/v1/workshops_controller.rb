# El taller (MT-97, Paper «v1 · 6 · Taller»): la portada de Maker Tracker. Un
# producto cada vez, lo siguiente que le toca definir a la persona (como mucho
# 5, en el orden del roadmap) y el resto plegado. Responder y marcar como Lista
# se hacen desde la tarjeta y vuelven aquí.
module V1
  class WorkshopsController < ApplicationController
    def show
      current = @project.current_milestone
      render inertia: "Workshop", props: {
        workshop: {
          items: workshop.items.map { item_props(it, current) },
          waiting: workshop.waiting_count,
          # Lo plegado («Mostrar»): solo lo justo para una línea por historia.
          waiting_items: workshop.all.drop(Workshop::LIMIT).map { waiting_props(it, current) },
          ready: workshop.ready_count,
          today: today,
          prompt: helpers.workshop_prompt(@project, workshop),
          products: Project.order(:name).with_attached_logo.map do |project|
            { key: project.key, name: project.name, url: project_v1_workshop_path(project), count: project == @project ? workshop.count : Workshop.new(project).count, logo: logo_url(project) }
          end
        }
      }
    end

    # Solo de Definiendo a Lista, y solo si ya no le falta nada (lo que el taller marca como «Revisar»):
    # una pantalla vieja o un POST a mano no deben devolver a Lista una historia en curso o hecha.
    def ready
      story = @project.stories.find_by!(number: params[:number])
      unless story.reviewable?
        return redirect_to project_v1_workshop_path(@project), notice: "#{story.reference} ya no está pendiente de tu OK"
      end
      story.move_to!("ready", actor: Current.actor)
      redirect_to project_v1_workshop_path(@project), notice: "#{story.reference} está Lista para construir"
    rescue Story::ClaimedByOther => e
      redirect_to project_v1_workshop_path(@project), notice: e.message
    end

    def answer
      story = @project.stories.find_by!(number: params[:number])
      question = story.questions.find(params[:question_id])
      story.answer_question!(question, option: Integer(params[:option].to_s), note: nil, actor: Current.actor)
      redirect_to project_v1_workshop_path(@project), notice: "Respondiste a #{question.actor.name} en #{story.reference}: «#{question.answer_text.truncate(80)}»"
    rescue Question::AlreadyAnswered
      redirect_to project_v1_workshop_path(@project), notice: "Esa pregunta ya estaba respondida."
    rescue ArgumentError, ActiveRecord::RecordInvalid
      redirect_to project_v1_workshop_path(@project), notice: "Elige una de las opciones."
    end

    private

    def milestone_label(story, current)
      story.milestone && [ story.milestone.code, story.milestone == current ? "Ahora" : nil ].compact.join(" ")
    end

    def waiting_props(item, current)
      story = item.story
      { kind: item.kind, ref: story.reference, title: story.title, milestone: milestone_label(story, current), url: project_v1_story_path(@project, story.number) }
    end

    def item_props(item, current)
      story = item.story
      props = { kind: item.kind, ref: story.reference, title: story.title, milestone: milestone_label(story, current),
                reason: helpers.workshop_reason(item), url: project_v1_story_path(@project, story.number),
                edit_url: edit_project_story_path(@project, story) }
      case item.kind
      when :review then props[:ready_url] = project_v1_workshop_story_ready_path(@project, story.number)
      when :answer
        if (question = item.question)
          props[:question] = question_props(question, answer_url: project_v1_workshop_story_answer_path(@project, story.number))
        end
      end
      props
    end

    DAYS = %w[domingo lunes martes miércoles jueves viernes sábado].freeze
    MONTHS = %w[ene feb mar abr may jun jul ago sep oct nov dic].freeze

    # «Lunes 23 nov»: la fecha de la cabecera (la app no tiene los nombres de los días en es.yml).
    def today
      date = Date.current
      "#{DAYS[date.wday]} #{date.day} #{MONTHS[date.month - 1]}"
    end

    def logo_url(project) = (rails_blob_path(project.logo, only_path: true) if project.logo.attached?)
  end
end
