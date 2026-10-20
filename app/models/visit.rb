# La última visita de Fran a la portada o a una historia (MT-31). Abrir la
# pantalla es mirarla: no hay botón «visto». Lo que se enseña es lo cambiado
# desde la visita anterior a esta, pero recargar la página no puede vaciarlo,
# así que las aperturas seguidas cuentan como una sola visita: la anterior
# solo pasa a ser el punto de partida cuando han pasado más de SESSION_GAP
# desde la última apertura.
class Visit < ApplicationRecord
  SESSION_GAP = 30.minutes

  belongs_to :story, optional: true

  # Marca la visita de ahora a `story` (o a la portada) y devuelve desde cuándo
  # enseñar los cambios, o nil si es la primera vez (no hay con qué comparar).
  def self.open!(story = nil, now: Time.current)
    transaction do
      visit = find_by(story: story)
      if visit.nil?
        create!(story: story, since: now, seen_at: now)
        next
      end

      visit.since = visit.seen_at if now - visit.seen_at > SESSION_GAP
      visit.seen_at = now
      visit.save!
      visit.since
    end
  end
end
