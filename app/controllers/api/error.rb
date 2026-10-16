# Un error de la API con su código tipado, el código HTTP, cómo arreglarlo
# (`hint`) y si tiene sentido reintentar. Api::BaseController lo convierte en
# el sobre de error.
class Api::Error < StandardError
  attr_reader :code, :status, :hint, :retryable, :details

  def initialize(code, message, status:, hint: nil, retryable: false, details: nil)
    super(message)
    @code, @status, @hint, @retryable, @details = code, status, hint, retryable, details
  end

  def self.not_found(message, hint: "Lista lo que hay con mt list o mt projects")
    new("NOT_FOUND", message, status: :not_found, hint: hint)
  end

  def self.validation(message, hint: nil, details: nil)
    new("VALIDATION_FAILED", message, status: :unprocessable_entity, hint: hint, details: details)
  end

  def as_json(*)
    { code: code, message: message, hint: hint, retryable: retryable, details: details }.compact
  end
end
