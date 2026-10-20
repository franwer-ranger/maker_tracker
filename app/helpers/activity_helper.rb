# Piezas de la portada de Actividad (MT-30).
module ActivityHelper
  NUMBER_WORDS = %w[cero una dos tres cuatro cinco seis siete ocho nueve diez].freeze

  # "Cinco cosas solo las puedes hacer tú. La más antigua lleva dos días esperando."
  def activity_summary(cards)
    count = cards.size
    words = NUMBER_WORDS[count] || count.to_s
    lead = count == 1 ? "Una cosa solo la puedes hacer tú." : "#{words.capitalize} cosas solo las puedes hacer tú."
    cards.one? ? lead : "#{lead} La más antigua lleva #{waiting_in_words(cards.first.since)} esperando."
  end

  # "2 días", "16 horas", "40 minutos".
  def waiting_in_words(time)
    seconds = Time.current - time
    if seconds < 1.hour then pluralize_es([ (seconds / 60).floor, 1 ].max, "minuto")
    elsif seconds < 1.day then pluralize_es((seconds / 1.hour).floor, "hora")
    else pluralize_es((seconds / 1.day).floor, "día")
    end
  end

  def pluralize_es(count, noun) = "#{count} #{noun}#{'s' unless count == 1}"

  # "desde 08:10", "desde ayer", "desde 12 oct".
  def since_label(time)
    day = relative_day(time)
    day == "hoy" ? "desde #{time.strftime('%H:%M')}" : "desde #{day}"
  end

  # El contador de «Te toca»: el número de tarjetas (nil si no hay ninguna).
  def activity_count = Activity.for_you.size.nonzero?

  # Lo que cuenta una tarjeta de historia en Definiendo, completo (escritorio) y corto (móvil).
  def definition_meta(card)
    waiting = short_time_ago(card.since)
    questions = card.reason == :questions
    safe_join([
      tag.span("en Definiendo · #{questions ? 'preguntas abiertas' : 'parada, sin cambios'} · espera #{waiting}", class: "hidden md:inline"),
      tag.span("Definiendo · #{questions ? 'preguntas' : 'parada'} · #{waiting}", class: "md:hidden")
    ])
  end

  # Primera línea de las preguntas abiertas del cuerpo de la historia, sin la viñeta.
  def open_questions_excerpt(story)
    line = story.open_questions_text.to_s.lines.map(&:strip).find(&:present?).to_s
    line.sub(/\A[-*]\s+(\[[ xX]\]\s+)?/, "").truncate(160)
  end

  # Una línea de «Lo último que ha pasado»: qué pasó, en qué historia.
  def recent_event_text(event)
    sentence = event_sentence(event)
    event.story ? "#{event.story.reference} · #{event.story.title} — #{sentence}" : sentence
  end

  # Pestaña de la barra inferior del móvil (5.9 · Móvil): icono, etiqueta y, si hay, el contador.
  def tab_item(label, href, icon:, active:, count: nil)
    link_to href, class: class_names("flex w-20 shrink-0 flex-col items-center gap-1 rounded-md py-1.5 text-label leading-[14px] #{ComponentsHelper::FOCUS_RING}",
      active ? "font-medium text-text" : "text-text-muted"), aria: { current: ("page" if active) } do
      safe_join([
        tag.span(class: "relative flex") do
          safe_join([
            icon(icon, size: 22),
            (tag.span(count, class: "absolute -right-2.5 -top-1.5 rounded-full bg-accent px-1.5 font-mono text-label leading-[14px] text-bg") if count)
          ].compact)
        end,
        label
      ])
    end
  end
end
