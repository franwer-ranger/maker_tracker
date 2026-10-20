# Cuánto trabajo les queda a los agentes (MT-33): por proyecto, las historias
# Listas y desbloqueadas de todos sus hitos abiertos y cuántas hay en Definiendo
# detrás. Es de todo el proyecto, no del hito que enseña el tablero. Se calcula
# al consultar, sin tabla propia, y es la única fuente de verdad: el bloque de
# Actividad, las cabeceras, el aviso de «Te toca» (`Activity`) y `mt context` /
# `mt roadmap` leen de aquí.
#
# «Desbloqueada» es `Story#blocked?` (historias sin hacer en `blocked_by` y
# preguntas bloqueantes abiertas), igual que `mt next`. Todo en un puñado de
# consultas para todos los proyectos, no una por historia ni por proyecto.
class ReadyWork
  # Con tantas Listas o menos, avisa en «Te toca». Fijo hasta que haga falta configurarlo.
  LOW = 2

  # `ready`: Listas y desbloqueadas. `defining`: sus historias en Definiendo, por
  # orden de roadmap. `pending`: cuántas historias sin hacer hay en hitos abiertos
  # (sin ellas el proyecto está terminado, no sin trabajo). `waiting_on_questions`:
  # alguna Lista solo está parada por una pregunta que ya espera a Fran.
  Summary = Data.define(:project, :ready, :defining, :pending, :waiting_on_questions) do
    def defining_count = defining.size

    # Poco trabajo: el aviso de «Te toca». Un proyecto terminado no cuenta, ni
    # el que no tiene ninguna libre solo por una pregunta que ya sale en «Te toca».
    def low? = pending.positive? && ready <= LOW && !(ready.zero? && waiting_on_questions)
  end

  # Memoizado por petición: la barra lateral (el contador de Actividad), la
  # pantalla y las cabeceras de proyecto lo piden a la vez.
  def self.all
    Current.ready_work ||= of(Project.order(:created_at).to_a)
  end

  # Resumen por id de proyecto.
  def self.of(projects)
    projects = Array(projects)
    return {} if projects.empty?

    stories = Story.where(project_id: projects.map(&:id), milestone_id: Milestone.open.select(:id)).where.not(state: :done)
      .includes(:milestone, :questions).order(:position).to_a
    done = done_numbers(projects, stories)
    by_project = stories.group_by(&:project_id)

    projects.index_by(&:id).to_h do |id, project|
      pending = by_project[id].to_a
      ready = pending.select(&:ready?)
      free = ready.reject { it.blocked?(done_numbers: done[id].to_a) }
      defining = pending.select(&:defining?).sort_by { [ it.milestone.position, it.position ] }
      waiting = ready.any? { it.pending_blockers(done_numbers: done[id].to_a).empty? }
      [ id, Summary.new(project: project, ready: free.size, defining: defining, pending: pending.size, waiting_on_questions: waiting) ]
    end
  end

  def self.for(project) = of([ project ]).fetch(project.id)

  # Los números hechos de cada proyecto; solo se consultan si alguna historia depende de otra.
  def self.done_numbers(projects, stories)
    return {} if stories.none? { it.blocked_by.any? }

    Story.done.where(project_id: projects.map(&:id)).pluck(:project_id, :number)
      .group_by(&:first).transform_values { |rows| rows.map(&:last) }
  end
  private_class_method :done_numbers
end
