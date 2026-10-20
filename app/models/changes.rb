# «Qué ha cambiado desde X» en un proyecto: los eventos posteriores a un
# instante, del más antiguo al más reciente. Es la consulta que comparten la
# daily del agente (MT-42, `Daily`) y «Mientras no mirabas» de la UI (MT-31): quien
# la use solo decide desde cuándo y qué ruido quita; la lógica de «desde cuándo»
# vive aquí y no se duplica. (No confundir con la actividad de la portada.)
#
#   Changes.new(project, since: visita.last_seen_at).events(limit: 40)
#   Changes.new(project, since: 1.week.ago, except_actor: Current.actor)
class Changes
  # Acciones que son contabilidad de la herramienta y no algo que le pasó al
  # producto: no salen en ningún «qué ha pasado».
  BOOKKEEPING = %w[daily.held].freeze

  attr_reader :project, :since, :until_time

  # `since`: instante (exclusivo). `until_time`: tope (inclusivo), para que lo
  # que se lee y lo que se marca como leído sean lo mismo. `except_actor`: deja
  # fuera lo que hizo ese actor (MT-31 no cuenta lo que hiciste tú).
  def initialize(project, since:, until_time: nil, except_actor: nil, story: nil)
    @project = project
    @since = since
    @until_time = until_time
    @except_actor = except_actor
    @story = story
  end

  # Lo mismo, solo de una historia (el bloque «Qué cambió desde tu visita»).
  def for_story(story) = self.class.new(project, since: since, until_time: until_time, except_actor: @except_actor, story: story)

  # En orden cronológico. Con `limit`, los N más recientes (sin cargar el resto).
  def events(limit: nil)
    rows = limit ? scope.reorder(occurred_at: :desc, id: :desc).limit(limit) : scope
    rows = rows.includes(:actor, :story, :project).to_a
    limit ? rows.reverse : rows
  end

  def size = @size ||= scope.count

  def empty? = size.zero?

  def actors = Actor.where(id: scope.reorder(nil).select(:actor_id)).order(:name).to_a

  private

  def scope
    scope = project.events.where("occurred_at > ?", since).where.not(action: BOOKKEEPING).order(:occurred_at, :id)
    scope = scope.where("occurred_at <= ?", until_time) if until_time
    scope = scope.where.not(actor: @except_actor) if @except_actor
    scope = scope.where(story: @story) if @story
    scope
  end
end
