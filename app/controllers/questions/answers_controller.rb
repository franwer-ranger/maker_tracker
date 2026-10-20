# Responde una pregunta de un agente desde la UI (MT-30): con una opción
# (botón), con una opción y una nota, o con texto libre. Como en la API, solo
# una persona responde (D-52), y la UI siempre es el actor humano.
class Questions::AnswersController < ApplicationController
  include ProjectScoped

  def create
    story = @project.stories.find_by!(number: params[:story_number])
    question = story.questions.find(params[:question_id])
    option = Integer(params[:option].to_s, exception: false)
    note = params[:note].to_s.strip.presence
    # Sin opción solo vale responder con texto libre (`free`), y con texto.
    if option.nil? && (params[:free].blank? || note.nil?)
      return redirect_back_or_to(project_story_path(@project, story), alert: "Elige una opción o escribe tu respuesta.", status: :see_other)
    end

    story.answer_question!(question, option: option, note: note, actor: Current.actor, decide: params[:decide] == "1")
    flash[:notice] = answered_notice(question) if from_activity?
    redirect_back_or_to project_story_path(@project, story), status: :see_other
  rescue Question::AlreadyAnswered
    redirect_back_or_to project_story_path(@project, story), alert: "Esa pregunta ya estaba respondida.", status: :see_other
  rescue ActiveRecord::RecordInvalid => e
    redirect_back_or_to project_story_path(@project, story), alert: e.record.errors.full_messages.to_sentence, status: :see_other
  end

  private

  def from_activity? = URI(request.referer.to_s).path == root_path

  # "Respondiste a codex en PG-49: «Avisar antes de publicar»".
  def answered_notice(question)
    "Respondiste a #{question.actor.name} en #{question.story.reference}: «#{question.answer_text.truncate(80)}»"
  end
end
