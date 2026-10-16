# Quién hace algo: Fran o un agente (claude, codex…). Sin login, es la forma
# de saber quién hizo qué.
class Actor < ApplicationRecord
  HUMAN_NAME = "fran".freeze
  TOKEN_PREFIX = "mt_".freeze

  enum :kind, { human: "human", agent: "agent" }, validate: true

  has_many :decisions, dependent: :restrict_with_exception
  has_many :comments, dependent: :restrict_with_exception
  has_many :claimed_stories, class_name: "Story", foreign_key: :claimed_by_id, inverse_of: :claimed_by, dependent: :restrict_with_exception

  normalizes :name, with: -> { it.strip.downcase }

  validates :name, presence: true, uniqueness: true, format: { with: /\A[a-z0-9_-]+\z/, message: :name_format }

  # El actor humano al que se atribuye todo lo que pasa en la UI (M1 tiene uno solo).
  def self.human
    human_kind.first || create_or_find_by!(name: HUMAN_NAME) { it.kind = :human }
  end

  scope :human_kind, -> { where(kind: :human).order(:id) }
  scope :with_token, -> { where.not(token_digest: nil).order(:name) }

  # El actor de un token de la API, o nil. El token tiene 32 caracteres
  # aleatorios, así que buscar por su SHA-256 basta; la comparación final es en
  # tiempo constante.
  def self.authenticate(token)
    return if token.blank? || !token.start_with?(TOKEN_PREFIX)

    digest = digest_token(token)
    actor = find_by(token_digest: digest)
    actor if actor && ActiveSupport::SecurityUtils.secure_compare(actor.token_digest, digest)
  end

  def self.digest_token(token) = OpenSSL::Digest::SHA256.hexdigest(token)

  # Genera un token nuevo, guarda solo su digest y lo devuelve en claro (es la
  # única vez que se ve). El anterior deja de valer. No es un evento de
  # proyecto: un actor no tiene proyecto.
  def regenerate_token!
    token = "#{TOKEN_PREFIX}#{SecureRandom.alphanumeric(32)}"
    update!(token_digest: self.class.digest_token(token), token_used_at: nil)
    token
  end

  # Como mucho una escritura por minuto, para no escribir en cada petición.
  def token_used!
    update_column(:token_used_at, Time.current) if token_used_at.nil? || token_used_at < 1.minute.ago
  end
end
