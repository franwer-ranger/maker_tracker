# Un hecho: quién hizo qué y cuándo. Solo se añaden; no se editan ni se borran.
# `action` es texto libre a propósito: en M4 llegarán acciones de herramientas
# externas que el núcleo no interpreta.
class Event < ApplicationRecord
  belongs_to :project
  belongs_to :story, optional: true
  belongs_to :actor

  attribute :occurred_at, default: -> { Time.current }

  scope :recent_first, -> { order(occurred_at: :desc, id: :desc) }

  validates :action, presence: true

  # Cada escritura se emite en directo (MT-36) para el proyecto y la portada; si
  # la hizo el actor de una petición de la API, además lo marca «escribiendo».
  # No es un callback de dominio: no cambia datos, solo avisa.
  after_create_commit :broadcast_write
  # Y decide si avisa por push (MT-47); el envío va en un job.
  after_create_commit -> { Push::Notifier.call(self) }

  def readonly? = persisted? || super

  # Un commit enlazado al terminar una historia (MT-44). `url` solo si se conoce
  # el repo, que sale del PR de GitHub del mismo evento.
  Commit = Data.define(:sha, :message, :url) do
    def short = sha.first(7)

    # "4f3e2a1 · Guarda el borrador"; sin asunto, solo el sha.
    def label = [ short, message ].compact.join(" · ")
  end

  # La única forma de leer los commits de un evento. Los eventos viejos los
  # guardan como lista de strings (solo el sha) y los nuevos como `{sha, message}`;
  # se normaliza al leer, sin migrar. Siempre una lista (vacía si no hay).
  def commits
    repo = data["pr"].to_s[%r{\Ahttps://github\.com/[^/]+/[^/]+(?=/pull/\d+)}]
    Array(data["commits"]).filter_map do |item|
      sha, message = item.is_a?(Hash) ? item.values_at("sha", "message") : [ item, nil ]
      sha = sha.to_s.strip
      Commit.new(sha: sha, message: message.to_s.strip.presence, url: ("#{repo}/commit/#{sha}" if repo && sha.match?(/\A\h{4,40}\z/))) if sha.present?
    end
  end

  private

  def broadcast_write
    locals = { event: self }
    Turbo::StreamsChannel.broadcast_append_later_to([ project, :writes ], target: "writes", partial: "presences/write", locals: locals)
    Turbo::StreamsChannel.broadcast_append_later_to(:writes, target: "writes", partial: "presences/write", locals: locals)
    if Current.actor == actor && actor.agent?
      Presence.wrote(self)
      Current.presence_written = true
    end
  rescue => e
    Rails.error.report(e, handled: true) # emitir no puede romper la escritura ya hecha
  end
end
