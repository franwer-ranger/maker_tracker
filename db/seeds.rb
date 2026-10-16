# Development data. Idempotent: it can be run several times without duplicating records.
#
# El proyecto Postgram de los mockups v2 (Paper → v2 · Agent-first: 4.2 Roadmap,
# 4.4 Historia · Lista (#49) y 4.6 Brief), para revisar las pantallas contra
# Paper. Los textos salen de esos artboards; lo que no detallan es inventado.

puts "Creating seeds..."

PAPER = "https://app.paper.design/file/01M50CA4S5CN4Z8ERVW36XWDHF".freeze

# Actores ---------------------------------------------------------------------

fran = Actor.human
claude = Actor.find_or_create_by!(name: "claude") { it.kind = :agent }
codex = Actor.find_or_create_by!(name: "codex") { it.kind = :agent }

# Proyecto y brief (4.6) ------------------------------------------------------

postgram = Project.find_or_initialize_by(key: "PG")
postgram.update!(name: "Postgram", brief: <<~MARKDOWN)
    ## Visión

    Postgram es el sitio donde un maker escribe una vez y publica en todas sus redes. Gana el que publica con constancia, no el que publica mejor; nuestro trabajo es quitar fricción hasta que publicar sea un hábito.

    ## Principios

    - Menos de 10 minutos a la semana.
    - Nada de dashboards que nadie mira: cada métrica sugiere una acción.
    - Un solo editor; las redes se adaptan, el maker no.

    ## Fuera de alcance

    Agencias y gestión de clientes. Generar contenido con IA por el usuario.

    ## Glosario

    Post: lo que escribe el maker, una vez. Publicación: cada copia de un post en una red.
MARKDOWN

# Hitos (4.2) -----------------------------------------------------------------

def seed_milestone(project, title, goal, closed_at: nil)
  milestone = project.milestones.find_or_initialize_by(title: title)
  milestone.closed_at = closed_at if milestone.new_record?
  milestone.update!(goal: goal)
  milestone
end

m1 = seed_milestone(postgram, "Cuentas y primer post", "Que un maker cree su cuenta, conecte una red y publique su primer post.", closed_at: 34.days.ago)
m2 = seed_milestone(postgram, "Publicar sin fricción", "Un maker programa una semana de posts en menos de 10 minutos.")
m3 = seed_milestone(postgram, "Analítica para makers", "Saber qué post funciona y por qué.")
m4 = seed_milestone(postgram, "Equipos", "Varias personas publicando en la misma cuenta.")

# Historias -------------------------------------------------------------------
# Los números son los del mockup. Se crean en orden: la posición dentro del hito
# es la de creación.

# Crea la historia o la pone al día (título, hito, estado, propiedades…).
# `on_create` solo se asigna al crearla (fechas que no deben moverse). Sin
# `claimed_by`, no la tiene nadie: así se deshace lo que dejen las pruebas.
def seed_story(project, number, title, milestone: nil, state: :idea, claimed_by: nil, on_create: {}, **attributes)
  story = project.stories.find_or_initialize_by(number: number)
  story.assign_attributes(on_create) if story.new_record?
  story.assign_attributes(title: title, milestone: milestone, state: state, claimed_by: claimed_by, **attributes)
  story.claimed_at = claimed_by ? story.claimed_at || on_create[:claimed_at] : nil
  story.save!
  story
end

def story_body(historia: "", criterios: [], fuera: "", notas: "")
  <<~MARKDOWN
    ## Contexto

    ## Historia

    #{historia}

    ## Criterios de aceptación

    #{criterios.each_with_index.map { |c, i| "#{i + 1}. #{c}" }.join("\n")}

    ## Fuera de alcance

    #{fuera}

    ## Notas para quien lo construya

    #{notas}

    ## Preguntas abiertas
  MARKDOWN
end

# M1 · cerrado, 9 hechas.
[
  "Registro con email", "Iniciar sesión con enlace mágico", "Conectar cuenta de X",
  "Editor de posts", "Publicar ahora en X", "Subir imágenes al post",
  "Perfil del maker", "Página de ajustes", "Correo de bienvenida"
].each.with_index(1) do |title, number|
  seed_story(postgram, number, title, milestone: m1, state: :done)
end

# Bandeja de ideas.
[
  [ "Hilos de X desde un post largo", %w[editor x] ],
  [ "Atajos de teclado en el editor", %w[editor] ],
  [ "Publicar en Bluesky", %w[redes] ],
  [ "Publicar en Mastodon", %w[redes] ],
  [ "Recordatorio semanal para planificar", %w[hábito] ],
  [ "Importar posts antiguos de X", %w[redes importación] ],
  [ "Etiquetas para organizar posts", [] ],
  [ "Modo oscuro en el editor", %w[editor] ],
  [ "App móvil para publicar", %w[móvil] ],
  [ "Sugerir la mejor hora para publicar", %w[analítica] ],
  [ "Plantillas compartidas con la comunidad", [] ],
  [ "Exportar todos los posts a CSV", %w[exportación] ],
  [ "Contador de caracteres por red", %w[editor redes] ],
  [ "Integración con Notion", %w[importación] ]
].each.with_index(10) do |(title, labels), number|
  seed_story(postgram, number, title, labels: labels)
end

# M4 · solo ideas.
[ "Invitar a otra persona a la cuenta", "Roles: editor y publicador", "Aprobar posts antes de publicar" ].each.with_index(24) do |title, number|
  seed_story(postgram, number, title, milestone: m4)
end

# M2 · en el orden de 5.1 Tablero y 5.3 Roadmap: 8 abiertas y 4 hechas.
# Las hechas primero: #49 está bloqueada por #47.
m2_done = [
  seed_story(postgram, 47, "Borradores automáticos", milestone: m2, state: :done, labels: %w[editor]),
  seed_story(postgram, 43, "Subir varias imágenes a la vez", milestone: m2, state: :done, labels: %w[editor]),
  seed_story(postgram, 42, "Conectar Instagram", milestone: m2, state: :done, labels: %w[redes]),
  seed_story(postgram, 41, "Conectar LinkedIn", milestone: m2, state: :done, labels: %w[redes])
]
m2_stories = [
  seed_story(postgram, 48, "Exportar post a PDF", milestone: m2, state: :in_progress, labels: %w[export],
             claimed_by: claude, on_create: { claimed_at: 18.minutes.ago },
             body: story_body(historia: "Como maker, quiero exportar un post a PDF para compartirlo fuera de las redes.")),
  seed_story(postgram, 45, "Programar publicaciones", milestone: m2, state: :in_progress, labels: %w[calendario],
             claimed_by: codex, on_create: { claimed_at: 1.day.ago.change(hour: 18) },
             body: story_body(historia: "Como maker, quiero programar un post para una fecha y hora, para preparar la semana de una vez.")),
  # El cuerpo es el markdown de 5.6 Historia · Editando (#49).
  seed_story(postgram, 49, "Plantillas de post reutilizables", milestone: m2, state: :ready,
             mockup: "#{PAPER}/p-C-0", labels: %w[editor ui], blocked_by: [ 47 ], body: <<~MARKDOWN),
               ## Contexto
               Los makers repiten el mismo formato cada semana.

               ## Historia
               Como maker que publica cada semana, quiero guardar un post como plantilla para no reescribir el mismo formato una y otra vez.

               ## Criterios de aceptación
               - [ ] Desde un post publicado, «Guardar como plantilla» crea una plantilla con el texto y las imágenes.
               - [ ] Al crear un post nuevo puedo elegir una plantilla y se rellena el editor.
               - [ ] Las variables {fecha} y {enlace} se sustituyen al usar la plantilla.

               ## Fuera de alcance
               Compartir plantillas entre cuentas (M4).

               ## Preguntas abiertas
             MARKDOWN
  seed_story(postgram, 50, "Vista previa por red social", milestone: m2, state: :ready,
             mockup: "#{PAPER}/p-C-0", labels: %w[editor],
             body: story_body(historia: "Como maker, quiero ver cómo quedará el post en cada red antes de publicarlo, para no llevarme sorpresas.")),
  seed_story(postgram, 51, "Métricas de engagement", milestone: m2, state: :defining, labels: %w[analítica],
             body: story_body(historia: "Como maker, quiero saber qué posts generan conversación, para repetir lo que funciona.")),
  seed_story(postgram, 54, "Reprogramar arrastrando en el calendario", milestone: m2, state: :defining,
             labels: %w[calendario], blocked_by: [ 45 ]),
  # Con una pregunta abierta: es el ejemplo de `mt move PG-52 ready` en docs/CLI.md.
  seed_story(postgram, 52, "Hilos de X en un solo post", milestone: m2, labels: %w[editor],
             body: Story::BODY_TEMPLATE + "¿Se publica como hilo también en Bluesky y Mastodon?\n"),
  seed_story(postgram, 53, "Programar desde el móvil", milestone: m2, labels: %w[móvil])
] + m2_done
# Fija el orden también en una base de datos sembrada antes.
m2_stories.each.with_index(1) { |story, position| story.update!(position: position) }

# M3 · 6 historias, 4 en Definiendo. Una está bloqueada por #51. La Lista va
# primera, como en el ejemplo de `mt roadmap` (docs/CLI.md).
m3_stories = [
  seed_story(postgram, 31, "Exportar métricas a CSV", milestone: m3, state: :ready, labels: %w[exportación]),
  seed_story(postgram, 27, "Panel de rendimiento por post", milestone: m3, state: :defining, labels: %w[analítica]),
  seed_story(postgram, 28, "Comparar redes", milestone: m3, state: :defining, labels: %w[analítica], blocked_by: [ 51 ]),
  seed_story(postgram, 29, "Resumen semanal por email", milestone: m3, state: :defining),
  seed_story(postgram, 30, "Mejores horas para publicar", milestone: m3, state: :defining, labels: %w[analítica]),
  seed_story(postgram, 32, "Alertas cuando un post despega", milestone: m3)
]
m3_stories.each.with_index(1) { |story, position| story.update!(position: position) }

# Decisiones (5.5) ------------------------------------------------------------
# El cuerpo es el porqué; se pinta tras «Por qué:», así que empieza en minúscula.

def seed_decision(project, number, title, body, actor:, at:, story: nil, supersedes: nil)
  project.decisions.find_or_create_by!(number: number) do |decision|
    decision.assign_attributes(title: title, body: body, actor: actor, story: story, supersedes: supersedes, created_at: at, updated_at: at)
  end
end

seed_decision(postgram, 9, "Imágenes en S3 desde el principio", "para no migrar cuando crezca el número de imágenes.", actor: fran, at: 30.days.ago)
seed_decision(postgram, 12, "Imágenes en Active Storage local", "un solo servidor; S3 cuando haga falta.", actor: fran, at: 14.days.ago,
              supersedes: postgram.decisions.find_by!(number: 9))
seed_decision(postgram, 13, "Publicar sin fricción va antes que Analítica", "los usuarios beta lo piden primero.", actor: fran, at: 1.day.ago)
seed_decision(postgram, 14, "PDFs con Prawn, sin servicios externos", "autoalojado y sin coste por documento.",
              actor: claude, at: 2.hours.ago, story: postgram.stories.find_by!(number: 48))

# Comentarios -----------------------------------------------------------------

def seed_comment(story, actor, body, at:)
  story.comments.find_or_create_by!(body: body) do |comment|
    comment.assign_attributes(actor: actor, created_at: at, updated_at: at)
  end
end

s48 = postgram.stories.find_by!(number: 48)
s45 = postgram.stories.find_by!(number: 45)
s49 = postgram.stories.find_by!(number: 49)

seed_comment(s49, claude, "He añadido los criterios y enlazado el mockup. Variables solo {fecha} y {enlace}: el resto, en otra historia.",
             at: 1.day.ago.change(hour: 22, min: 31))
seed_comment(s48, claude, "Empiezo con Prawn, como dice D-14. ¿El export incluye los comentarios o solo el post?", at: 15.minutes.ago)

# Eventos ---------------------------------------------------------------------
# Solo los que se ven en los mockups. Se añaden a mano y solo si la historia aún
# no los tiene, para que las seeds sigan siendo idempotentes.

def seed_event(project, action, actor:, at:, story: nil, data: {})
  data = data.deep_stringify_keys
  return if project.events.where(story: story, action: action, actor: actor).any? { it.data == data }

  project.events.create!(story: story, action: action, actor: actor, data: data, occurred_at: at)
end

# #49 (5.4 · Historial): creada como idea → pasa a Definiendo → claude la define → pasa a Lista.
seed_event(postgram, "story.created", story: s49, actor: fran, at: 13.days.ago.change(hour: 16, min: 20), data: { state: "idea", milestone_id: m2.id })
seed_event(postgram, "story.state_changed", story: s49, actor: fran, at: 7.days.ago.change(hour: 10, min: 5), data: { from: "idea", to: "defining" })
seed_event(postgram, "story.edited", story: s49, actor: claude, at: 1.day.ago.change(hour: 22, min: 31), data: { fields: %w[body mockup] })
seed_event(postgram, "story.state_changed", story: s49, actor: fran, at: 1.day.ago.change(hour: 22, min: 40), data: { from: "defining", to: "ready" })

seed_event(postgram, "story.claimed", story: s48, actor: claude, at: s48.claimed_at)
seed_event(postgram, "story.claimed", story: s45, actor: codex, at: s45.claimed_at)

# Brief editado hace 3 días (5.5).
seed_event(postgram, "brief.edited", actor: fran, at: 3.days.ago)

# Segundo proyecto (5.0 Proyectos): un hito abierto, sin historias y sin actividad desde hace 2 días.

maker_tracker = Project.find_or_create_by!(key: "MT") { it.name = "Maker Tracker" }
seed_milestone(maker_tracker, "Núcleo v2", "El modelo nuevo funcionando, con la UI mínima para definir producto.")
seed_event(maker_tracker, "project.created", actor: fran, at: 2.days.ago)

puts "Seeds created!"
