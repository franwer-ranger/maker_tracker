# La última visita de Fran a la portada o a una historia (MT-31). Abrir la
# pantalla es mirarla: no hay botón «visto». Lo que se enseña es lo cambiado
# desde la visita anterior a esta, pero recargar la página no puede vaciarlo,
# así que las aperturas seguidas cuentan como una sola visita: la anterior
# solo pasa a ser el punto de partida cuando han pasado más de SESSION_GAP
# desde la última apertura.
class Visit < ApplicationRecord
  SESSION_GAP = 30.minutes
  # No se escribe si la última apertura fue hace menos de esto.
  WRITE_EVERY = 1.minute
  HOME = "home".freeze

  belongs_to :story, optional: true

  def self.key_for(story) = story ? "story-#{story.id}" : HOME

  # Marca la visita de ahora a `story` (o a la portada) y devuelve desde cuándo
  # enseñar los cambios, o nil si no hay con qué comparar. Con `mark: false`
  # (precarga de Turbo: pasar el ratón por un enlace) solo lo calcula.
  def self.open!(story = nil, now: Time.current, mark: true)
    key = key_for(story)
    visit = find_by(key: key)
    unless visit
      # La primera vez en una historia, lo que la portada marcó como cambiado también cuenta aquí.
      since = story ? find_by(key: HOME)&.since : nil
      return since unless mark

      visit = create_or_find_by!(key: key) { it.assign_attributes(story: story, since: since || now, seen_at: now) }
      return since if visit.previously_new_record?
    end

    since = visit.seen_at && now - visit.seen_at > SESSION_GAP ? visit.seen_at : visit.since
    if mark && (since != visit.since || now - visit.seen_at >= WRITE_EVERY)
      visit.update!(since: since, seen_at: now)
    end
    since < now ? since : nil
  end
end
