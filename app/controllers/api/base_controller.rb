# Base de la API para agentes (historia #015). JSON siempre, sin sesión ni CSRF:
# el actor sale del token (`Authorization: Bearer mt_…`) y queda en
# Current.actor. Toda respuesta va en el mismo sobre:
#
#   { ok: true, data:, summary:, breadcrumbs: [], warnings: [] }
#   { ok: false, error: { code:, message:, hint:, retryable: } }
#
# Los breadcrumbs son comandos de `mt`: es lo que el agente va a ejecutar.
class Api::BaseController < ActionController::API
  # mt comprueba en cada respuesta que conoce esta versión.
  before_action { response.set_header("X-MT-API-Version", Api::Operations::VERSION.to_s) }
  before_action :authenticate_actor
  skip_before_action :authenticate_actor, only: :route_not_found

  rescue_from StandardError, with: :render_internal_error
  rescue_from Api::Error, with: :render_error
  rescue_from ActiveRecord::RecordNotFound do |e|
    render_error Api::Error.not_found(e.model ? "No existe ese #{e.model.underscore.humanize.downcase}" : e.message)
  end
  rescue_from ActiveRecord::RecordInvalid do |e|
    render_error Api::Error.validation(e.record.errors.full_messages.to_sentence, details: e.record.errors.to_hash(true))
  end
  rescue_from ActionController::ParameterMissing do |e|
    render_error Api::Error.validation("Falta el parámetro #{e.param}", hint: "Revisa los parámetros de la operación en GET /api")
  end
  rescue_from ActionDispatch::Http::Parameters::ParseError do
    render_error Api::Error.validation("El cuerpo no es JSON válido", hint: "Manda Content-Type: application/json y un objeto JSON")
  end
  rescue_from Story::ClaimedByOther do |e|
    render_error Api::Error.new("CLAIMED_BY_OTHER", e.message, status: :conflict,
      hint: "Elige otra con mt next o pide a Fran que la libere")
  end
  rescue_from Eventable::ReasonRequired do |e|
    render_error Api::Error.new("REASON_REQUIRED", e.message, status: :unprocessable_entity,
      hint: "Repite la operación con --reason \"…\" explicando por qué")
  end

  # /api/<lo que sea que no existe>
  def route_not_found
    raise Api::Error.not_found("No existe #{request.method} #{request.path}", hint: "Las operaciones están en GET /api")
  end

  private

  def authenticate_actor
    token = request.authorization.to_s[/\ABearer\s+(\S+)\z/, 1]
    actor = Actor.authenticate(token)
    unless actor
      raise Api::Error.new("UNAUTHORIZED", token ? "El token no es válido" : "Falta el token",
        status: :unauthorized,
        hint: "Manda Authorization: Bearer <token>. Pide uno en el servidor con bin/rails \"mt:token[tu-nombre]\" y configúralo con mt setup <url> <token>")
    end

    actor.token_used!
    Current.actor = actor
  end

  def render_ok(data = {}, summary:, breadcrumbs: [], warnings: [], status: :ok)
    body = { ok: true, data: data, summary: summary, breadcrumbs: breadcrumbs }
    body[:warnings] = warnings if warnings.any?
    render json: body, status: status
  end

  def render_error(error)
    render json: { ok: false, error: error }, status: error.status
  end

  def render_internal_error(exception)
    raise exception if Rails.env.local? && ENV["API_RAISE"] # para depurar con la pantalla de errores

    Rails.error.report(exception, handled: true)
    Rails.logger.error([ "#{exception.class}: #{exception.message}", *exception.backtrace&.first(10) ].join("\n"))
    render_error Api::Error.new("INTERNAL", "Error interno: #{exception.message}", status: :internal_server_error,
      hint: "Es un fallo de Maker Tracker, no de la petición. Avisa a Fran con este mensaje", retryable: true)
  end

  # Proyecto por su clave (PG), no por el slug.
  def project
    @project ||= Project.find_by(key: params[:project_key].to_s.upcase) ||
      raise(Api::Error.not_found("No existe el proyecto #{params[:project_key]}", hint: "Los proyectos están en mt projects"))
  end

  # Historia por su número: 49 o PG-49.
  def story
    @story ||= find_story(params[:story_number] || params[:number])
  end

  # Hito por su código (M2) o su título.
  def find_milestone(value)
    value = value.to_s.strip
    milestone = project.milestones.find_by(position: value[/\AM(\d+)\z/i, 1]) if value.match?(/\AM\d+\z/i)
    milestone ||= project.milestones.find_by("LOWER(title) = ?", value.downcase)
    milestone || raise(Api::Error.not_found("No existe el hito #{value} en #{project.key}", hint: "Los hitos están en mt roadmap --closed"))
  end

  def find_story(reference)
    number = reference.to_s.sub(/\A#{Regexp.escape(project.key)}-/i, "")
    project.stories.find_by(number: Integer(number, exception: false)) ||
      raise(Api::Error.not_found("No existe #{project.key}-#{number}", hint: "Busca la historia con mt list o mt roadmap"))
  end
end
