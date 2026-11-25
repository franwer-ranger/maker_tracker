# `mt attach PG-49 captura.png` y `mt attach tablero captura.png` (MT-96): sube
# un adjunto (multipart, en el campo `file`) a una historia o a una página de la
# documentación y devuelve su enlace en markdown para pegarlo en el cuerpo. El
# enlace es relativo a la instancia; `url` es el mismo, absoluto, para descargarlo.
class Api::AttachmentsController < Api::BaseController
  rescue_from Attachable::Invalid do |e|
    render_error Api::Error.validation(e.english, hint: "attach images, videos, PDF, text or archives of up to 100 MB.")
  end

  def create
    file = params.require(:file)
    unless file.respond_to?(:read)
      raise Api::Error.validation("file must be a file, sent as multipart/form-data.", hint: "use mt attach <story|page> <file>.")
    end

    attachment = record.attach_file!(file, filename: file.original_filename, content_type: file.content_type, actor: Current.actor)
    data = Api::Markdown::Formatting.attachment_data(attachment, base_url: request.base_url)
    render_ok(data.merge(markdown: "#{data[:markdown]}\n"), status: :created,
      summary: "#{data[:filename]} attached to #{label} (#{data[:size]}).",
      breadcrumbs: [ edit_command ])
  end

  private

  def record
    @record ||= if params[:page_slug]
      project.pages.find_by(slug: params[:page_slug].to_s.downcase) ||
        raise(Api::Error.not_found("no page #{params[:page_slug]} in #{project.key}.", hint: "see them with mt doc."))
    else
      story
    end
  end

  def label = record.is_a?(Story) ? record.reference : "page #{record.slug}"

  def edit_command = record.is_a?(Story) ? "mt edit #{record.reference} --file <f.md>" : "mt doc edit #{record.slug} --file <f.md>"
end
