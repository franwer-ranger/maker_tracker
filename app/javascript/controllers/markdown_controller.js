import { Controller } from "@hotwired/stimulus"
import { marked } from "marked"
import DOMPurify from "dompurify"

// Pinta markdown (GFM, con casillas) en `output`. El texto sale de `source`
// (un <textarea>, oculto o el del editor) y se vuelve a pintar si cambia.
// Las secciones `##` que están vacías no se enseñan. Tras un repintado en
// directo (morph, MT-38) el servidor trae `output` vacío: se vuelve a pintar.
// Los adjuntos citados por su nombre, `![pie](attachment:captura.png)` (MT-122),
// se resuelven con `attachments` (nombre → enlace); el que no existe sale como
// un hueco con «Falta la imagen captura.png», nunca como una imagen rota.
const REFERENCE = /(!?\[[^\]]*\]\()attachment:([^)\s]+)\)/g
const MISSING = "#falta-adjunto:"

export default class extends Controller {
  static targets = ["source", "output"]
  static values = { attachments: Object }

  connect() {
    this.render()
    this.rerender = () => this.render()
    document.addEventListener("turbo:morph", this.rerender)
  }

  disconnect() {
    document.removeEventListener("turbo:morph", this.rerender)
  }

  render() {
    const text = this.#resolveAttachments(this.sourceTarget.value)
    const html = DOMPurify.sanitize(marked.parse(text, { gfm: true }))
    this.outputTarget.innerHTML = html
    this.#markMissing()
    this.#playVideos()
    this.#hideEmptySections()
  }

  // Los vídeos adjuntos (MT-96) van en el markdown como imágenes, `![](…mp4)`:
  // se pintan como <video> para que se reproduzcan.
  #playVideos() {
    this.outputTarget.querySelectorAll("img").forEach((image) => {
      if (!/\.(mp4|webm|mov)$/i.test(new URL(image.src, location.href).pathname)) return
      const video = document.createElement("video")
      video.src = image.src
      video.controls = true
      video.preload = "metadata"
      video.setAttribute("aria-label", image.alt)
      image.replaceWith(video)
    })
  }

  #resolveAttachments(text) {
    return text.replace(REFERENCE, (_, start, name) => {
      const key = decodeName(name)
      const link = Object.hasOwn(this.attachmentsValue, key) ? this.attachmentsValue[key] : MISSING + name
      return `${start}${link})`
    })
  }

  #markMissing() {
    this.outputTarget.querySelectorAll(`img[src^="${MISSING}"]`).forEach((element) => {
      const name = decodeName(element.getAttribute("src").slice(MISSING.length))
      const gap = document.createElement("span")
      gap.className = "missing-attachment"
      gap.textContent = `Falta la imagen ${name}`
      element.replaceWith(gap)
    })
  }

  #hideEmptySections() {
    this.outputTarget.querySelectorAll("h2").forEach((heading) => {
      const next = heading.nextElementSibling
      if (!next || next.tagName === "H2") heading.remove()
    })
  }
}

function decodeName(name) {
  try {
    return decodeURIComponent(name)
  } catch {
    return name
  }
}
