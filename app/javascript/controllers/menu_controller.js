import { Controller } from "@hotwired/stimulus"

// Cierra un menú <details> al pulsar fuera o con Escape. Al abrirlo, enfoca
// lo que tenga autofocus (p. ej. el campo de «Nueva idea» en el móvil).
export default class extends Controller {
  toggle() {
    if (this.element.open) {
      this.outside = (event) => { if (!this.element.contains(event.target)) this.close() }
      this.escape = (event) => { if (event.key === "Escape") { this.close(); this.element.querySelector("summary").focus() } }
      document.addEventListener("click", this.outside)
      document.addEventListener("keydown", this.escape)
      this.element.querySelector("[autofocus]")?.focus()
    } else {
      this.#unlisten()
    }
  }

  close() {
    this.element.open = false
  }

  disconnect() {
    this.#unlisten()
  }

  #unlisten() {
    document.removeEventListener("click", this.outside)
    document.removeEventListener("keydown", this.escape)
  }
}
