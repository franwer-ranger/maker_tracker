import { Controller } from "@hotwired/stimulus"

// Pestañas Escribir / Vista previa del editor de markdown.
export default class extends Controller {
  static targets = ["tab", "input", "preview"]

  write() {
    this.#show(0)
    this.inputTarget.focus()
  }

  preview() {
    this.#show(1)
  }

  #show(index) {
    this.tabTargets.forEach((tab, i) => tab.setAttribute("aria-selected", i === index))
    this.inputTarget.classList.toggle("hidden", index !== 0)
    this.previewTarget.classList.toggle("hidden", index !== 1)
  }
}
