// `bin/ci` («Frontend: partir y juntar el cuerpo», `npm run check:body`): con cuerpos raros, juntar lo partido
// devuelve el cuerpo byte a byte y editar una sección cambia solo esa. Sin framework: falla con la primera que no.
import { fromRaw, joinBody, parseBody, plain, type Section } from "./story-body.ts"

const TEMPLATE = ["Contexto", "Historia", "Criterios de aceptación", "Cómo probarlo", "Qué cambia del producto", "Fuera de alcance", "Notas para quien lo construya", "Preguntas abiertas"]

const BODIES: Record<string, string> = {
  vacio: "",
  "solo texto": "Una línea sin secciones",
  plantilla: [
    "## Contexto", "<!-- Por qué hace falta. -->", "", "## Historia", "Como (usuario), quiero (hacer algo), para (cumplir un objetivo).", "",
    "## Criterios de aceptación", "<!-- Uno por línea, comprobable, como casilla de markdown. -->", "", "## Fuera de alcance", "", "## Preguntas abiertas", "",
  ].join("\n"),
  "código con ## dentro": "## Contexto\nMira:\n\n```md\n## Esto no es sección\ntexto\n```\n\nDespués del bloque.\n\n## Historia\nComo yo.\n",
  "tildes y bloque largo": "## Contexto\n~~~~\n## no\n~~~\n## tampoco\n~~~~\nfin\n\n## Historia\nx\n",
  "bloque sin cerrar": "## Contexto\n```\n## dentro\n",
  "comentario de varias líneas": "## Contexto\n<!--\n## no es sección\n-->\ntexto\n## Historia\ny",
  crlf: "Antes\r\n\r\n## Contexto\r\n<!-- guía -->\r\n\r\nUno\r\ndos\r\n\r\n\r\n## Historia\r\nComo yo.\r\n",
  "sin salto final": "## Contexto\n\ntexto",
  "repetidos": "## Notas\nuna\n\n## Notas\notra\n\n## Notas\n",
  "sangrías y espacios": "## Contexto\n    código indentado\n  sigue   \n\n\n\n## Historia   \n\t tab\n\n",
  "preámbulo y ###": "Texto previo.\n\n### Sub\n\n## Contexto\n### Dentro\nalgo\n<!-- en medio -->\nmás\n## Fuera de plantilla\nlibre\n",
  "solo encabezado": "## Contexto",
  "lineas en blanco": "\n\n\n## Contexto\n\n\n\ntexto\n\n\n\n",
}

let checks = 0
const fail = (name: string, what: string, actual: unknown, expected: unknown) => {
  throw new Error(`${name} · ${what}\n  esperaba ${JSON.stringify(expected)}\n  sale     ${JSON.stringify(actual)}`)
}
const expect = (name: string, what: string, actual: unknown, expected: unknown) => {
  checks++
  if (JSON.stringify(actual) !== JSON.stringify(expected)) fail(name, what, actual, expected)
}
const edit = (body: string, id: number, text: (section: Section) => string) => {
  const parsed = parseBody(body, TEMPLATE)
  return joinBody({ ...parsed, sections: parsed.sections.map((s) => (s.id === id ? { ...s, text: text(s) } : s)) })
}

for (const [name, body] of Object.entries(BODIES)) {
  for (const template of [[], TEMPLATE]) {
    const parsed = parseBody(body, template)
    expect(name, "juntar lo partido", joinBody(parsed), body)
    expect(name, "ids sin repetir", new Set(parsed.sections.map((s) => s.id)).size, parsed.sections.length)
  }
  // Editar cada sección que estaba: cambia su trozo y solo el suyo.
  const original = parseBody(body).sections
  let offset = parseBody(body).preamble.length
  for (const section of original) {
    for (const [what, next] of [["añadir", (s: Section) => (s.text ? `${s.text} [tocado]` : "nuevo")], ["vaciar", () => ""]] as const) {
      const after = edit(body, section.id, next)
      const prefix = body.slice(0, offset)
      const suffix = body.slice(offset + section.raw.length)
      const where = `${what} «${section.heading}» (${section.id})`
      if (!after.startsWith(prefix)) fail(name, `${where}: lo de antes`, after.slice(0, prefix.length), prefix)
      if (!after.endsWith(suffix)) fail(name, `${where}: lo de después`, after.slice(after.length - suffix.length), suffix)
      checks += 2
      const reparsed = parseBody(after).sections
      expect(name, `${where}: las mismas secciones`, reparsed.map((s) => s.heading), original.map((s) => s.heading))
      expect(name, `${where}: su texto`, reparsed[section.id].text, next(section).replace(/\r/g, ""))
      if (what === "vaciar" && !section.text) expect(name, `${where}: vaciar la vacía no cambia nada`, after, body)
    }
    offset += section.raw.length
  }
}

// El modo Markdown: sin cambiar nada, el cuerpo tal cual; cambiado, con los saltos que tenía.
for (const [name, body] of Object.entries(BODIES)) expect(name, "Markdown sin cambiar", fromRaw(plain(body), body), body)
expect("crlf", "Markdown cambiado", fromRaw(plain(BODIES.crlf).replace("Antes", "Después"), BODIES.crlf), BODIES.crlf.replace("Antes", "Después"))
expect("crlf", "preámbulo editado en Markdown", parseBody(fromRaw(plain(BODIES.crlf).replace("Antes", "Otro"), BODIES.crlf)).preamble, "Otro\r\n\r\n")

// Los casos de la verificación, con el resultado exacto.
const code = BODIES["código con ## dentro"]
expect("código", "secciones", parseBody(code).sections.map((s) => s.heading), ["Contexto", "Historia"])
expect("código", "tocar Contexto", edit(code, 0, (s) => `${s.text} [tocado]`), code.replace("Después del bloque.", "Después del bloque. [tocado]"))
expect("código", "tocar Historia", edit(code, 1, () => "Como tú."), code.replace("Como yo.", "Como tú."))
const crlf = BODIES.crlf
expect("crlf", "tocar con varias líneas", edit(crlf, 0, () => "Uno\ntres"), crlf.replace("Uno\r\ndos", "Uno\r\ntres"))
const plantilla = BODIES.plantilla
expect("plantilla", "rellenar una vacía", edit(plantilla, 0, () => "Porque sí."), plantilla.replace("<!-- Por qué hace falta. -->\n", "<!-- Por qué hace falta. -->\n\nPorque sí.\n"))
expect("plantilla", "vaciar Historia", edit(plantilla, 1, () => ""), plantilla.replace("Como (usuario), quiero (hacer algo), para (cumplir un objetivo).\n", ""))
const added = parseBody(plantilla, TEMPLATE)
const cuesta = added.sections.find((s) => s.heading === "Cómo probarlo")!
expect("plantilla", "una que faltaba, en su sitio", joinBody({ ...added, sections: added.sections.map((s) => (s === cuesta ? { ...s, text: "En QA." } : s)) }),
  plantilla.replace("## Fuera de alcance", "## Cómo probarlo\n\nEn QA.\n\n## Fuera de alcance"))
const repetidos = BODIES.repetidos
expect("repetidos", "tocar la segunda", edit(repetidos, 1, () => "cambiada"), repetidos.replace("otra", "cambiada"))
expect("repetidos", "rellenar la tercera", edit(repetidos, 2, () => "tercera"), `${repetidos}\ntercera\n`)
expect("vacío", "rellenar Contexto", edit("", parseBody("", TEMPLATE).sections[0].id, () => "Algo."), "## Contexto\n\nAlgo.\n")
expect("sin salto final", "tocar", edit(BODIES["sin salto final"], 0, () => "otro"), "## Contexto\n\notro")
expect("preámbulo", "se conserva", parseBody(BODIES["preámbulo y ###"]).preamble, "Texto previo.\n\n### Sub\n\n")

console.log(`Cuerpo de historia: ${Object.keys(BODIES).length} cuerpos y ${checks} comprobaciones, todo igual.`)
