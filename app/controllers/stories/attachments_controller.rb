# Pegar o arrastrar un archivo en el editor de una historia (MT-96): lo sube y
# devuelve, en JSON, el markdown que el editor deja donde estaba el cursor:
# `markdown` con el enlace de Active Storage (el editor antiguo) y `reference`
# por su nombre, `![captura.png](attachment:captura.png)` (MT-122, el de la v1).
class Stories::AttachmentsController < ApplicationController
  include ProjectScoped

  def create
    story = @project.stories.find_by!(number: params[:story_number])
    file = params.require(:file)
    return render json: { error: "Falta el archivo." }, status: :unprocessable_entity unless file.respond_to?(:read)

    attachment = story.attach_file!(file, filename: file.original_filename, content_type: file.content_type, actor: Current.actor)
    render json: { markdown: Attachable.markdown(attachment), reference: Attachable.reference(attachment), filename: attachment.filename.to_s }, status: :created
  rescue Attachable::Invalid => e
    render json: { error: e.message }, status: :unprocessable_entity
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.record.errors.full_messages.to_sentence }, status: :unprocessable_entity
  rescue ActionController::ParameterMissing
    render json: { error: "Falta el archivo." }, status: :unprocessable_entity
  end
end
