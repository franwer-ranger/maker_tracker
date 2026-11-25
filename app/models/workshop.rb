# El taller (MT-97, D-97): lo que a la persona le toca definir en un producto,
# en el orden del roadmap. Sustituye a «Te toca»: la QA es de Relay. Lo leen la
# portada (V1::WorkshopsController) y el agente (`mt workshop`), en el mismo orden.
#
# Cada cosa es una historia con lo único que le falta, por este orden:
# - :answer   una pregunta abierta (la más antigua), en cualquier estado menos Hecha,
#             o preguntas abiertas escritas en el cuerpo de una en Definiendo;
# - :criteria en Definiendo y sin criterios;
# - :design   en Definiendo, de interfaz (label `ui`) y sin mockup;
# - :review   en Definiendo, con criterios y sin preguntas: falta pasarla a Lista.
# Se calcula al consultar, sin tabla propia.
class Workshop
  LIMIT = 5

  Item = Data.define(:kind, :story, :question)

  attr_reader :project

  # El producto que abre la portada: el primero (por nombre) que tenga algo que definir.
  def self.default_project
    projects = Project.order(:name).to_a
    projects.find { new(it).any? } || projects.first
  end

  def initialize(project)
    @project = project
  end

  # Lo siguiente: como mucho LIMIT, en el orden del roadmap.
  def items = all.first(LIMIT)

  # Todo lo que espera a una definición, en el orden del roadmap.
  def all
    @all ||= roadmap_order(candidates).filter_map do |story|
      question = story.open_questions_asked.first
      kind = if question || (story.defining? && story.open_questions?) then :answer
      elsif story.missing_criteria? then :criteria
      elsif story.labels.include?("ui") && story.mockup.blank? then :design
      elsif story.defining? then :review
      end
      Item.new(kind: kind, story: story, question: question) if kind
    end
  end

  def count = all.size

  def any? = all.any?

  # El resto, en espera: lo que no entra en los LIMIT primeros.
  def waiting_count = count - items.size

  def ready_count = @ready_count ||= project.stories.ready.count

  private

  # Las de Definiendo y las no hechas con alguna pregunta abierta.
  def candidates
    with_questions = project.questions.open.select(:story_id)
    project.stories.where(state: "defining").or(project.stories.where(id: with_questions).where.not(state: "done"))
      .includes(:milestone, questions: :actor).to_a
  end

  # Hitos abiertos en su orden, después la bandeja y al final los cerrados.
  def roadmap_order(stories)
    stories.sort_by do |story|
      milestone = story.milestone
      group = if milestone.nil? then 1 elsif milestone.closed? then 2 else 0 end
      [ group, milestone&.position.to_i, story.position.to_i, story.number ]
    end
  end
end
