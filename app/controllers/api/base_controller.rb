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
  # Presencia (MT-36): cada petición autenticada marca al actor como activo.
  after_action :record_presence, unless: -> { Current.actor.nil? }

  rescue_from StandardError, with: :render_internal_error
  rescue_from Api::Error, with: :render_error
  rescue_from ActiveRecord::RecordNotFound do |e|
    render_error Api::Error.not_found(e.model ? "#{e.model.underscore.humanize.downcase} not found." : "#{e.message}.")
  end
  rescue_from ActiveRecord::RecordInvalid do |e|
    render_error Api::Error.validation("#{e.record.errors.full_messages.to_sentence}.", details: e.record.errors.to_hash(true))
  end
  rescue_from ActionController::ParameterMissing do |e|
    render_error Api::Error.validation("missing parameter #{e.param}.", hint: "the parameters of each operation are in GET /api.")
  end
  rescue_from ActionDispatch::Http::Parameters::ParseError do
    render_error Api::Error.validation("the body is not valid JSON.", hint: "send Content-Type: application/json and a JSON object.")
  end
  # Las excepciones de dominio llevan su mensaje en castellano para la UI: la
  # API escribe el suyo.
  rescue_from Story::ClaimedByOther do |e|
    render_error claimed_by_other_error(e.story)
  end
  rescue_from Versioned::Conflict do |e|
    render_error conflict_error(e)
  end
  rescue_from Eventable::ReasonRequired do
    render_error reason_required_error
  end

  # La API habla inglés aunque la UI vaya en castellano (docs/CLI.md → Idioma).
  # Envuelve también los rescue_from, que construyen los mensajes de error.
  def process_action(...) = I18n.with_locale(:en) { super }

  # /api/<lo que sea que no existe>
  def route_not_found
    raise Api::Error.not_found("no such operation: #{request.method} #{request.path}.", hint: "the operations are in GET /api.")
  end

  private

  def authenticate_actor
    token = request.authorization.to_s[/\ABearer\s+(\S+)\z/, 1]
    actor = Actor.authenticate(token)
    unless actor
      raise Api::Error.new("UNAUTHORIZED", token ? "the token is not valid." : "missing token.",
        status: :unauthorized,
        hint: "send Authorization: Bearer <token>. Create one on the server with bin/rails \"mt:token[your-name]\" and set it with mt setup <url> <token>.")
    end

    actor.token_used!
    Current.actor = actor
  end

  # GET lee, el resto escribe. Solo si la respuesta es 2xx: un 404 o un 422 no
  # dejan presencia. Si la escritura ya marcó la presencia con su evento
  # (Presence.wrote), no se pisa. Sin proyecto en la ruta también cuenta.
  def record_presence
    return if Current.presence_written || !response.successful?

    reading = request.get? || request.head?
    key = params[:project_key].to_s.upcase.presence
    Presence.touch(Current.actor, project: (@project || Project.find_by(key: key) if key), project_key: key, target: presence_target(key),
      mode: reading ? :reading : :writing, detail: reading ? nil : "#{controller_name}##{action_name}")
  rescue => e
    Rails.error.report(e, handled: true) # la presencia nunca rompe una petición
  end

  def presence_target(key)
    if key && (number = params[:story_number] || params[:number])
      "#{key}-#{number.to_s.upcase.delete_prefix("#{key}-")}"
    elsif key && params[:code]
      "#{key} #{params[:code].to_s.upcase}"
    elsif controller_name != "projects"
      controller_name.singularize
    end
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
    render_error Api::Error.new("INTERNAL", "internal error: #{exception.message}", status: :internal_server_error,
      hint: "it's a bug in Maker Tracker, not in your request. Tell #{Actor.human.name} with this message.", retryable: true)
  end

  # Proyecto por su clave (PG), no por el slug.
  def project
    @project ||= Project.find_by(key: params[:project_key].to_s.upcase) ||
      raise(Api::Error.not_found("no project #{params[:project_key].to_s.upcase}.", hint: "see them with mt projects."))
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
    milestone || raise(Api::Error.not_found("no milestone #{value} in #{project.key}.", hint: "see them with mt roadmap --closed."))
  end

  # "PG-48 is claimed by claude since 11:42."
  def claimed_by_other_error(story)
    since = " since #{Api::Markdown::Formatting.datetime(story.claimed_at)}" if story.claimed_at
    Api::Error.new("CLAIMED_BY_OTHER", "#{story.reference} is claimed by #{story.claimed_by.name}#{since}.", status: :conflict,
      hint: "pick another one with mt next, or ask #{Actor.human.name} to release it.")
  end

  # "PG-49 changed since you read it: claude edited it at 10:42 (you had version 4, it is on 5)."
  def conflict_error(conflict)
    record = conflict.record
    at = Api::Markdown::Formatting.datetime(conflict.edited_at) if conflict.edited_at
    by = " (#{[ conflict.editor&.name, at ].compact.join(', ')})" if conflict.editor || at
    subject, reread = case record
    when Story then [ record.reference, "mt show #{record.reference}" ]
    when Milestone then [ record.code, "mt milestone show #{record.code}" ]
    else [ "the brief of #{record.name}", "mt brief" ]
    end
    Api::Error.new("CONFLICT", "#{subject} changed since you read it (you had version #{conflict.expected}, it is on #{conflict.current}). Nothing was saved.",
      status: :conflict, details: { expected_version: conflict.expected, current_version: conflict.current },
      hint: "Someone changed it#{by}. Read it again with #{reread} and apply your changes on top.")
  end

  # Cada controlador que pide motivo dice cómo repetir el comando con él.
  def reason_required_error = reason_error("this", "repeat it with --reason \"why\".")

  # "reordering needs a reason." + el comando completo como hint.
  def reason_error(doing, command)
    Api::Error.new("REASON_REQUIRED", "#{doing} needs a reason.", status: :unprocessable_entity, hint: command)
  end

  def find_story(reference)
    number = reference.to_s.sub(/\A#{Regexp.escape(project.key)}-/i, "")
    project.stories.find_by(number: Integer(number, exception: false)) ||
      raise(Api::Error.not_found("#{project.key}-#{number} does not exist.", hint: "find it with mt list or mt roadmap."))
  end
end
