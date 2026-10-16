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

postgram = Project.find_or_create_by!(key: "PG") do |project|
  project.name = "Postgram"
  project.brief = <<~MARKDOWN
    ## Visión

    Postgram es el sitio donde un maker escribe una vez y publica en todas sus redes. Gana el que publica con constancia, no el que publica mejor; nuestro trabajo es quitar fricción hasta que publicar sea un hábito.

    ## Principios

    - Menos de 10 minutos a la semana.
    - Nada de dashboards que nadie mira: cada métrica sugiere una acción.
    - Un solo editor; las redes se adaptan, el maker no.

    ## Fuera de alcance

    Agencias y gestión de clientes. Generar contenido con IA por el usuario.

    ## Glosario
  MARKDOWN
end

# Hitos (4.2) -----------------------------------------------------------------

def seed_milestone(project, title, goal, closed_at: nil)
  project.milestones.find_or_create_by!(title: title) do |milestone|
    milestone.goal = goal
    milestone.closed_at = closed_at
  end
end

m1 = seed_milestone(postgram, "Cuentas y primer post", "Que un maker cree su cuenta, conecte una red y publique su primer post.", closed_at: 34.days.ago)
m2 = seed_milestone(postgram, "Publicar sin fricción", "Un maker programa una semana de posts en menos de 10 minutos.")
m3 = seed_milestone(postgram, "Analítica para makers", "Saber qué post funciona y por qué.")
m4 = seed_milestone(postgram, "Equipos", "Varias personas publicando en la misma cuenta.")

# Historias -------------------------------------------------------------------
# Los números son los del mockup. Se crean en orden: la posición dentro del hito
# es la de creación.

def seed_story(project, number, title, milestone: nil, state: :idea, **attributes)
  project.stories.find_or_create_by!(number: number) do |story|
    story.assign_attributes(title: title, milestone: milestone, state: state, **attributes)
  end
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

# M2 · en el orden del roadmap (4.2).
seed_story(postgram, 48, "Exportar post a PDF", milestone: m2, state: :in_progress,
           claimed_by: claude, claimed_at: 18.minutes.ago,
           body: story_body(historia: "Como maker, quiero exportar un post a PDF para compartirlo fuera de las redes."))
seed_story(postgram, 45, "Programar publicaciones", milestone: m2, state: :in_progress,
           claimed_by: codex, claimed_at: 1.day.ago.change(hour: 18),
           body: story_body(historia: "Como maker, quiero programar un post para una fecha y hora, para preparar la semana de una vez."))
seed_story(postgram, 49, "Plantillas de post reutilizables", milestone: m2, state: :ready,
           mockup: "#{PAPER}/p-8-0",
           body: story_body(
             historia: "Como maker que publica cada semana, quiero guardar un post como plantilla para no reescribir el mismo formato una y otra vez.",
             criterios: [
               "Desde un post publicado, «Guardar como plantilla» crea una plantilla con el texto y las imágenes",
               "Al crear un post nuevo puedo elegir una plantilla y se rellena el editor",
               "Las variables {fecha} y {enlace} se sustituyen al usar la plantilla"
             ],
             fuera: "Compartir plantillas entre cuentas (M4).",
             notas: "Reutiliza el editor actual; no hace falta un editor nuevo. Ver decisión D-12 sobre almacenamiento de imágenes."
           ))
seed_story(postgram, 50, "Vista previa por red social", milestone: m2, state: :ready,
           mockup: "#{PAPER}/p-8-0", labels: %w[editor redes],
           body: story_body(historia: "Como maker, quiero ver cómo quedará el post en cada red antes de publicarlo, para no llevarme sorpresas."))
seed_story(postgram, 51, "Métricas de engagement", milestone: m2, state: :defining,
           body: story_body(historia: "Como maker, quiero saber qué posts generan conversación, para repetir lo que funciona."))
{ 41 => "Conectar LinkedIn", 42 => "Publicar en varias redes a la vez", 43 => "Borradores automáticos", 47 => "Cola de publicación" }.each do |number, title|
  seed_story(postgram, number, title, milestone: m2, state: :done)
end

# M3 · 6 historias, 4 en Definiendo. Una está bloqueada por #51.
seed_story(postgram, 27, "Panel de rendimiento por post", milestone: m3, state: :defining, labels: %w[analítica])
seed_story(postgram, 28, "Comparar redes", milestone: m3, state: :defining, labels: %w[analítica], blocked_by: [ 51 ])
seed_story(postgram, 29, "Resumen semanal por email", milestone: m3, state: :defining)
seed_story(postgram, 30, "Mejores horas para publicar", milestone: m3, state: :defining, labels: %w[analítica])
seed_story(postgram, 31, "Exportar métricas a CSV", milestone: m3, state: :ready, labels: %w[exportación])
seed_story(postgram, 32, "Alertas cuando un post despega", milestone: m3)

# Decisiones (4.6) ------------------------------------------------------------

def seed_decision(project, number, title, body, actor:, at:, story: nil)
  project.decisions.find_or_create_by!(number: number) do |decision|
    decision.assign_attributes(title: title, body: body, actor: actor, story: story, created_at: at, updated_at: at)
  end
end

seed_decision(postgram, 12, "Imágenes en Active Storage local", "Un solo servidor; S3 cuando haga falta.", actor: fran, at: 14.days.ago)
seed_decision(postgram, 13, "Publicar sin fricción va antes que Analítica", "Los usuarios beta lo piden primero.", actor: fran, at: 1.day.ago)
seed_decision(postgram, 14, "PDFs con Prawn, sin servicios externos", "Autoalojado y sin coste por documento.",
              actor: fran, at: 2.hours.ago, story: postgram.stories.find_by!(number: 48))

# Comentarios -----------------------------------------------------------------

def seed_comment(story, actor, body, at:)
  story.comments.find_or_create_by!(body: body) do |comment|
    comment.assign_attributes(actor: actor, created_at: at, updated_at: at)
  end
end

s48 = postgram.stories.find_by!(number: 48)
s45 = postgram.stories.find_by!(number: 45)
s49 = postgram.stories.find_by!(number: 49)

seed_comment(s49, claude, "Añadidos los tres criterios y los dos mockups de Paper (selector de plantilla y guardar como plantilla).", at: 1.day.ago.change(hour: 22, min: 31))
seed_comment(s49, fran, "Perfecto, la paso a Lista.", at: 1.day.ago.change(hour: 22, min: 40))
seed_comment(s48, claude, "Empiezo con Prawn, como dice D-14. ¿El export incluye los comentarios o solo el post?", at: 15.minutes.ago)

# Eventos ---------------------------------------------------------------------
# Solo los que se ven en los mockups. Se añaden a mano y solo si la historia aún
# no los tiene, para que las seeds sigan siendo idempotentes.

def seed_event(story, action, actor:, at:, data: {})
  return if story.events.exists?(action: action, actor: actor)

  story.project.events.create!(story: story, action: action, actor: actor, data: data, occurred_at: at)
end

# #49 (4.4 · Historial): creada desde una idea → claude la define → pasa a Lista.
seed_event(s49, "story.created", actor: fran, at: 13.days.ago, data: { state: "defining", milestone_id: m2.id })
seed_event(s49, "story.edited", actor: claude, at: 1.day.ago.change(hour: 22, min: 31), data: { fields: %w[body mockup] })
seed_event(s49, "story.state_changed", actor: fran, at: 1.day.ago.change(hour: 22, min: 40), data: { from: "defining", to: "ready" })

seed_event(s48, "story.claimed", actor: claude, at: s48.claimed_at)
seed_event(s45, "story.claimed", actor: codex, at: s45.claimed_at)

puts "Seeds created!"
