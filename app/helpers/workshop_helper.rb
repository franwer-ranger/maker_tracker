# Textos del taller (MT-97): lo único que le falta a cada historia y el prompt
# de «Copiar para tu agente», que lleva lo siguiente a una entrevista corta.
module WorkshopHelper
  def workshop_reason(item)
    story = item.story
    case item.kind
    when :answer
      question = item.question
      question ? "#{question.actor.name} pregunta#{' y bloquea' if question.blocking?}: #{question.title}" : "Tiene preguntas abiertas en el cuerpo."
    when :criteria then "Le faltan los criterios de aceptación."
    when :design then "Es de interfaz y no tiene mockup."
    when :review
      "#{story.mockup.present? ? 'Tiene mockup, criterios' : 'Tiene criterios'} y ninguna pregunta. Solo falta tu OK para que se pueda construir."
    end
  end

  # Solo de este producto: lo siguiente, en orden, y cómo cerrarlo con `mt`.
  def workshop_prompt(project, workshop)
    items = workshop.items
    lines = items.each_with_index.map do |item, index|
      "#{index + 1}. #{item.story.reference} · #{item.story.title} — #{WORKSHOP_KINDS.fetch(item.kind)}: #{workshop_reason(item)}"
    end
    <<~PROMPT
      Entrevista corta de producto en Maker Tracker (#{project.name}, #{project.key}). Lee el taller con `mt workshop --project #{project.key}` y repasa conmigo #{items.size == 1 ? 'lo siguiente' : "estas #{items.size}"}, una a una y en este orden, con preguntas cortas y tu recomendación:

      #{lines.join("\n")}

      Cuando decidamos algo, déjalo en Maker Tracker: criterios y mockup con `mt edit`, mi respuesta a una pregunta con `mt answer` (la doy yo) y, con mi OK, `mt move <historia> ready`.
    PROMPT
  end

  WORKSHOP_KINDS = { answer: "Responder", criteria: "Escribir criterios", design: "Diseñar", review: "Revisar y dar el OK" }.freeze
end
