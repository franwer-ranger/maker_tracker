// Partir el cuerpo de una historia en sus secciones `## …` y volver a juntarlo (MT-112). El editor toca historias
// reales de todos los proyectos, así que juntar sin haber tocado nada devuelve el cuerpo byte a byte, y tocar una
// sección cambia solo su texto: el resto (CRLF, líneas en blanco, sangrías, comentarios y el salto final) se queda
// tal cual. Un `## ` dentro de un bloque de código o de un comentario no es una sección. Lo comprueba
// `story-body.check.ts` en `bin/ci`.

// Una sección tal como está en el cuerpo: `raw` es su trozo entero, `head` es el encabezado con lo que lo sigue hasta el texto (las guías de
// la plantilla y las líneas en blanco), `tail` lo que queda tras el texto hasta la siguiente. `text` es lo que se
// edita, con saltos `\n`; `original`, el que tenía. `present`: si estaba en el cuerpo (las de la plantilla que
// faltan se enseñan vacías y solo se añaden si se escribe algo). `id`: su sitio al partir, que no se repite aunque
// se repita el encabezado.
export type Section = { id: number; heading: string; raw: string; head: string; text: string; original: string; tail: string; present: boolean }
export type Body = { preamble: string; sections: Section[]; eol: string }

const COMMENT = /^\s*<!--[\s\S]*?-->\s*$/
const FENCE = /^ {0,3}(`{3,}|~{3,})/

// Las líneas con su salto, sin perder ninguno (el último puede no tenerlo).
const linesOf = (text: string) => text.match(/[^\n]*\n|[^\n]+$/g) ?? []
const bare = (line: string) => line.replace(/\r?\n$/, "")
const blank = (line: string) => !bare(line).trim()

// Las líneas `## ` que abren sección: fuera de bloques de código (``` o ~~~) y de comentarios de varias líneas.
function headingLines(lines: string[]) {
  const starts: number[] = []
  let fence: string | null = null
  let comment = false
  lines.forEach((raw, index) => {
    const line = bare(raw)
    if (fence) {
      const close = line.match(FENCE)
      if (close && close[1][0] === fence[0] && close[1].length >= fence.length && !line.slice(close[0].length).trim()) fence = null
      return
    }
    if (comment) {
      if (line.includes("-->")) comment = line.lastIndexOf("<!--") > line.lastIndexOf("-->")
      return
    }
    const open = line.match(FENCE)
    if (open) { fence = open[1]; return }
    if (line.startsWith("## ")) starts.push(index)
    if (line.includes("<!--")) comment = line.lastIndexOf("<!--") > line.lastIndexOf("-->")
  })
  return starts
}

function section(chunk: string[], id: number): Section {
  const heading = bare(chunk[0]).replace(/^## /, "").trim()
  // Tras el encabezado, las guías (comentarios del principio) y las líneas en blanco son de `head`.
  let start = 1
  while (start < chunk.length && (blank(chunk[start]) || COMMENT.test(bare(chunk[start])))) start++
  let end = chunk.length
  while (end > start && blank(chunk[end - 1])) end--
  const raw = chunk.join("")
  if (start === end) return { id, heading, raw, head: raw, text: "", original: "", tail: "", present: true }
  const body = chunk.slice(start, end)
  const last = body[body.length - 1]
  const lastEol = last.slice(bare(last).length)
  const text = body.map(bare).join("\n")
  return { id, heading, raw, head: chunk.slice(0, start).join(""), text, original: text, tail: lastEol + chunk.slice(end).join(""), present: true }
}

// Las secciones de la plantilla que faltan van vacías en su sitio de la plantilla.
export function parseBody(body: string, template: string[] = []): Body {
  const lines = linesOf(body)
  const starts = headingLines(lines)
  const preamble = lines.slice(0, starts[0] ?? lines.length).join("")
  const sections = starts.map((start, index) => section(lines.slice(start, starts[index + 1] ?? lines.length), index))
  let id = sections.length
  template.forEach((heading, index) => {
    if (sections.some((s) => s.heading === heading)) return
    const before = template.slice(0, index).reverse().find((previous) => sections.some((s) => s.heading === previous))
    const at = before ? sections.findIndex((s) => s.heading === before) + 1 : 0
    sections.splice(at, 0, { id: id++, heading, raw: "", head: "", text: "", original: "", tail: "", present: false })
  })
  return { preamble, sections, eol: body.includes("\r\n") ? "\r\n" : "\n" }
}

// Una sección como va en el cuerpo: la que no se tocó, tal cual; la tocada, con su encabezado y lo que la rodea
// como estaban y el texto nuevo en medio.
function render(section: Section, eol: string, before: string) {
  if (section.text === section.original) return section.raw
  const text = section.text.replace(/\r?\n/g, eol)
  const empty = !section.text.trim()
  if (!section.present) {
    if (empty) return ""
    const gap = !before ? "" : before.endsWith(`${eol}${eol}`) || before === eol ? "" : before.endsWith("\n") ? eol : eol + eol
    return `${gap}## ${section.heading}${eol}${eol}${text}${eol}`
  }
  if (section.original) {
    if (!empty) return section.head + text + section.tail
    // Vaciada: el encabezado y las guías, y la separación que tenía con la siguiente.
    const core = section.head.replace(/(\r?\n)(?:[ \t]*\r?\n)*$/, "$1")
    return core + section.tail.replace(/^\r?\n/, "")
  }
  if (empty) return section.head
  // Estaba vacía: el texto tras una línea en blanco, antes de la separación con la siguiente.
  const lines = linesOf(section.head)
  let end = lines.length
  while (end > 1 && blank(lines[end - 1])) end--
  const core = lines.slice(0, end).join("")
  const after = lines.slice(end).join("")
  const coreEol = core.endsWith("\n") ? "" : eol
  return core + coreEol + eol + text + (section.head.endsWith("\n") ? eol : "") + after
}

export function joinBody({ preamble, sections, eol }: Body) {
  let body = preamble
  let added = false
  for (const s of sections) {
    const part = render(s, eol, body)
    // Tras una sección añadida, una línea en blanco antes de la siguiente (entre dos añadidas la pone `render`).
    if (added && part && s.present) body += eol
    if (part) added = !s.present
    body += part
  }
  return body
}

// El cuerpo en crudo (modo Markdown) se edita con saltos `\n`, que es lo que da un textarea. Si no se cambió, el
// cuerpo de partida tal cual; si se cambió y era CRLF, sigue siéndolo.
export const plain = (body: string) => body.replace(/\r\n/g, "\n")
export function fromRaw(edited: string, base: string) {
  if (edited === plain(base)) return base
  return base.includes("\r\n") ? edited.replace(/\r?\n/g, "\r\n") : edited
}

// El texto de la primera sección con ese encabezado, sin espacios alrededor.
export const sectionText = (sections: Section[], heading: string) => sections.find((s) => s.heading === heading)?.text.trim() ?? ""
