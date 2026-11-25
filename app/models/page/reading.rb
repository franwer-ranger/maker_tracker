# La página de una capacidad leída como documentación viva (MT-103, «v1 · 3 ·
# Producto · Capacidad»): su markdown partido en las piezas que pinta la UI.
#
# - `lead`: la frase de debajo del título. El primer párrafo antes de ningún
#   `##` o, si no hay, el primero de «Qué hace hoy» / «Qué es».
# - `rules`: «Cómo funciona» (o «Reglas»). Cada regla es un `###` con su texto
#   o una viñeta (`**Título**: texto`, o la primera frase como título). Las
#   decisiones que cita (`D-52`) van aparte, a la derecha.
# - `questions`: «¿Qué pasa si…?». Un `###` con su respuesta o una viñeta
#   (`**¿…?** respuesta`, o hasta el primer `?`).
# - `sections`: el resto de secciones, tal cual, en párrafos, listas y `###`.
#
# Nunca pierde texto: «Cómo funciona» y «¿Qué pasa si…?» solo se parten en
# entradas si no tienen nada más (intro, cierre, código); si no, salen como
# prosa en `sections`, igual que todo lo que no reconoce.
#
# Las líneas que son solo una captura de la página (`attachments`, sus
# `Attachable.path`) no se pintan aquí: son «El recorrido». Las demás imágenes
# se quedan como párrafo. Una sección que no existe o se queda vacía no sale.
class Page::Reading
  RULES = /\A(c[oó]mo funciona|reglas)\b/i
  QUESTIONS = /\A¿?\s*qu[eé] pasa si/i
  LEAD = /\Aqu[eé] (hace( hoy)?|es)\b/i
  DECISION = /\bD-\d+\b/
  # Un bloque de código cercado entero (se aparta antes de partir: dentro no hay `##` ni párrafos).
  FENCE = /^```[^\n]*\n.*?^```[ \t]*$/m
  FENCE_MARK = /\A\uE000(\d+)\uE000\z/
  IMAGE_LINE = /^[ \t]*!\[[^\]]*\]\([^)]*\)[ \t]*$/
  BULLET = /\A\s*(?:[-*+]|\d+\.)\s+/
  # «(D-52 · D-91)», «(D-45)», «— D-45» o «… móvil. D-45» al final: solo referencias, se quitan del texto.
  ONLY_DECISIONS = /\s*(?:\((?:\s*D-\d+\s*[,·y]?\s*)+\)|[—–-]\s*(?:D-\d+\s*[,·y]?\s*)+\z|(?<=[.!?])\s*(?:D-\d+\s*[,·y]?\s*)+\z)/

  attr_reader :lead, :rules, :questions, :sections

  def initialize(body, attachments: [])
    @fences = []
    text = body.to_s.gsub("\r\n", "\n").gsub(FENCE) { "\n\n#{fence(it)}\n\n" }
    text = text.gsub(IMAGE_LINE) { screenshot?(it, attachments) ? "" : it }.strip
    preamble, *chunks = text.split(/^## +/)
    parsed = chunks.map { |chunk| chunk.split("\n", 2).then { |title, rest| [ title.strip, rest.to_s.strip ] } }

    @lead, preamble_rest = take_first_paragraph(preamble.to_s.strip)
    @sections = []
    @sections << { title: nil, blocks: blocks(preamble_rest) } if preamble_rest.present?

    parsed.each do |title, content|
      if @lead.nil? && title.match?(LEAD)
        @lead, content = take_first_paragraph(content)
        title = nil if @sections.empty? && @rules.nil? # lo que sigue a la frase va sin título
      end
      if title&.match?(RULES) && @rules.nil? && only_items?(content)
        @rules = items(content).map { rule(*it) }
      elsif title&.match?(QUESTIONS) && @questions.nil? && only_items?(content)
        @questions = items(content).map { question(*it) }
      elsif content.present?
        @sections << { title: title, blocks: blocks(content) }
      end
    end
  end

  def to_h = { lead: lead, rules: rules, questions: questions, sections: sections.reject { it[:blocks].empty? } }

  private

  # La línea `![…](url)` es una captura de la página (Attachable.markdown escapa los paréntesis).
  def screenshot?(line, attachments)
    url = line[/\]\(([^)\s]*)/, 1].to_s.gsub("%28", "(").gsub("%29", ")")
    attachments.any? { it.gsub("%28", "(").gsub("%29", ")") == url }
  end

  # [primer párrafo, lo demás], si el primer bloque es un párrafo de texto.
  def take_first_paragraph(text)
    first, rest = text.split(/\n\s*\n/, 2)
    return [ nil, text ] if first.blank? || first.match?(/\A\s*([-*+] |\d+\. |#|```|>|\||\uE000)/)

    [ first.squish, rest.to_s.strip ]
  end

  # La sección es solo entradas: `###` desde la primera línea, o todos sus
  # bloques viñetas. Con una intro, un cierre o código, va entera como prosa.
  def only_items?(content)
    return false if content.blank? || content.include?("\uE000")
    return content.start_with?("### ") if content.match?(/^### /)

    content.split(/\n\s*\n/).reject(&:blank?).all? { it.match?(BULLET) }
  end

  # Las entradas de una sección: [título, texto] por `###`, o [viñeta, nil] por cada viñeta.
  def items(content)
    if content.match?(/^### /)
      content.split(/^### +/).drop(1).map { it.split("\n", 2).then { |head, rest| [ head.strip, rest.to_s.squish.presence ] } }
    else
      bullets(content).map { [ it, nil ] }
    end
  end

  def bullets(content)
    content.split(/^\s*(?:[-*+]|\d+\.)\s+/).drop(1).map(&:squish).reject(&:blank?)
  end

  def rule(head, text)
    title, text = split_bullet(head, /[.:]\s+/) if text.nil?
    decisions = [ title, text ].join(" ").scan(DECISION).uniq
    { title: strip_decisions(title).presence || title, text: text && strip_decisions(text).presence, decisions: decisions }
  end

  def question(head, text)
    head, text = split_bullet(head, /(?<=\?)\s+/) if text.nil?
    { question: head, answer: text }
  end

  # «**Título**: texto» → [Título, texto]; sin negrita, se corta en el primer `separator`.
  def split_bullet(bullet, separator)
    if (match = bullet.match(/\A\*\*(.+?)\*\*[\s.:—–-]*(.*)\z/))
      [ match[1].strip, match[2].strip.upcase_first.presence ]
    else
      title, text = bullet.split(separator, 2)
      [ title.strip.delete_suffix("."), text&.strip&.upcase_first.presence ]
    end
  end

  def strip_decisions(text) = text.gsub(ONLY_DECISIONS, "").strip

  # Aparta un bloque cercado y deja en su sitio una marca que `blocks` restaura.
  def fence(code)
    @fences << code
    "\uE000#{@fences.size - 1}\uE000"
  end

  # Párrafos, listas, subtítulos y código, en orden.
  def blocks(content)
    content.split(/\n\s*\n/).flat_map do |chunk|
      chunk = chunk.strip
      next [] if chunk.empty?

      if (mark = chunk.match(FENCE_MARK))
        [ { type: "code", text: @fences[mark[1].to_i].sub(/\A```[^\n]*\n/, "").sub(/\n?```[ \t]*\z/, "") } ]
      elsif chunk.start_with?("### ")
        heading, rest = chunk.delete_prefix("### ").split("\n", 2)
        [ { type: "heading", text: heading.strip }, *blocks(rest.to_s) ]
      elsif chunk.match?(BULLET)
        [ { type: chunk.match?(/\A\s*\d+\./) ? "ordered" : "list", items: bullets(chunk) } ]
      else
        [ { type: "paragraph", text: chunk.squish } ]
      end
    end
  end
end
