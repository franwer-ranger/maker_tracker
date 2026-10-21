import { Controller } from "@hotwired/stimulus"
import { marked } from "marked"
import DOMPurify from "dompurify"

// Pinta markdown (GFM, con casillas) en `output`. El texto sale de `source`
// (un <textarea>, oculto o el del editor) y se vuelve a pintar si cambia.
// Las secciones `##` que están vacías no se enseñan. Tras un repintado en
// directo (morph, MT-38) el servidor trae `output` vacío: se vuelve a pintar.
export default class extends Controller {
  static targets = ["source", "output"]

  connect() {
    this.render()
    this.rerender = () => this.render()
    document.addEventListener("turbo:morph", this.rerender)
  }

  disconnect() {
    document.removeEventListener("turbo:morph", this.rerender)
  }

  render() {
    const text = this.sourceTarget.value
    const html = DOMPurify.sanitize(marked.parse(text, { gfm: true }))
    this.outputTarget.innerHTML = html
    this.#hideEmptySections()
  }

  #hideEmptySections() {
    this.outputTarget.querySelectorAll("h2").forEach((heading) => {
      const next = heading.nextElementSibling
      if (!next || next.tagName === "H2") heading.remove()
    })
  }
}
