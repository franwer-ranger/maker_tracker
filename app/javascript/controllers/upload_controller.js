import { Controller } from "@hotwired/stimulus"

// Pegar (⌘V) o arrastrar archivos en el editor de markdown (MT-96): cada uno se
// sube a `url` y su enlace queda donde estaba el cursor. Mientras sube, un
// marcador «Subiendo…»; si el servidor lo rechaza, el motivo en `status`.
export default class extends Controller {
  static targets = ["input", "status"]
  static values = { url: String }

  paste(event) {
    const files = [...(event.clipboardData?.files || [])]
    if (files.length === 0) return
    event.preventDefault()
    files.forEach((file) => this.#upload(file))
  }

  dragover(event) {
    if (event.dataTransfer?.types?.includes("Files")) event.preventDefault()
  }

  drop(event) {
    const files = [...(event.dataTransfer?.files || [])]
    if (files.length === 0) return
    event.preventDefault()
    files.forEach((file) => this.#upload(file))
  }

  async #upload(file) {
    const name = file.name || "captura.png"
    const marker = `[Subiendo ${name}…]()`
    this.#insert(marker)
    this.#say("")

    const body = new FormData()
    body.append("file", file, name)
    try {
      const response = await fetch(this.urlValue, {
        method: "POST", body,
        headers: { Accept: "application/json", "X-CSRF-Token": document.querySelector("meta[name=csrf-token]")?.content || "" }
      })
      const data = await response.json()
      if (!response.ok) throw new Error(data.error || `No se pudo subir ${name}.`)
      this.#replace(marker, data.markdown)
    } catch (error) {
      this.#replace(marker, "")
      this.#say(error.message)
    }
  }

  #insert(text) {
    const input = this.inputTarget
    const { selectionStart: start, selectionEnd: end, value } = input
    const before = value.slice(0, start)
    const padded = (before && !before.endsWith("\n") ? "\n" : "") + text + "\n"
    input.setRangeText(padded, start, end, "end")
    input.dispatchEvent(new Event("input", { bubbles: true }))
  }

  #replace(marker, text) {
    const input = this.inputTarget
    const at = input.value.indexOf(marker)
    if (at === -1) return
    input.setRangeText(text, at, at + marker.length, "preserve")
    input.dispatchEvent(new Event("input", { bubbles: true }))
  }

  #say(message) {
    if (!this.hasStatusTarget) return
    this.statusTarget.textContent = message
    this.statusTarget.classList.toggle("hidden", !message)
  }
}
