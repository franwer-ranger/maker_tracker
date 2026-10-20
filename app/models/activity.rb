# «Qué ha pasado desde X» en un proyecto: los eventos posteriores a un instante,
# del más antiguo al más reciente. Es la consulta que comparten la daily del
# agente (MT-42, `Daily`) y «Mientras no mirabas» de la UI (MT-31): quien la
# use solo decide desde cuándo y qué ruido quita; la lógica de «desde cuándo»
# vive aquí y no se duplica.
#
#   Activity.new(project, since: visita.last_seen_at).events
#   Activity.new(project, since: 1.week.ago, except_actor: Current.actor)
class Activity
  # Acciones que son contabilidad de la herramienta y no algo que le pasó al
  # producto: no salen en ningún «qué ha pasado».
  BOOKKEEPING = %w[daily.held].freeze

  attr_reader :project, :since

  # `since`: instante (exclusivo). `except_actor`: deja fuera lo que hizo ese
  # actor (MT-31 no cuenta lo que hiciste tú).
  def initialize(project, since:, except_actor: nil)
    @project = project
    @since = since
    @except_actor = except_actor
  end

  def events
    @events ||= scope.includes(:actor, :story).to_a
  end

  def empty? = events.empty?

  def size = events.size

  def actors = events.map(&:actor).uniq

  # Los eventos de una historia concreta o, con nil, los que no son de ninguna.
  def for_story(story) = events.select { it.story_id == story&.id }

  private

  def scope
    scope = project.events.where("occurred_at > ?", since).where.not(action: BOOKKEEPING).order(:occurred_at, :id)
    scope = scope.where.not(actor: @except_actor) if @except_actor
    scope
  end
end
