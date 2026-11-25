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

  #hideEmptySections() {
    this.outputTarget.querySelectorAll("h2").forEach((heading) => {
      const next = heading.nextElementSibling
      if (!next || next.tagName === "H2") heading.remove()
    })
  }
}
