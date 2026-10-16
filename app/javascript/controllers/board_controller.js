import { Controller } from "@hotwired/stimulus"
import Sortable from "sortablejs"

// Tablero: arrastrar entre columnas cambia el estado (Story#move_to!) y
// arrastrar dentro de una columna reordena en el hito (Story#reorder!).
// Si el servidor lo rechaza, la tarjeta vuelve a su sitio y se ve el error.
export default class extends Controller {
  static targets = ["column", "error"]
  static values = { sortable: Boolean, stateUrl: String, positionUrl: String }

  columnTargetConnected(column) {
    column.sortable = Sortable.create(column, {
      group: "board",
      sort: this.sortableValue,
      animation: 150,
      easing: "cubic-bezier(0.32, 0.72, 0, 1)",
      ghostClass: "opacity-40",
      onEnd: (event) => this.#dropped(event)
    })
  }

  columnTargetDisconnected(column) {
    column.sortable?.destroy()
  }

  async #dropped({ item, from, to, oldIndex, newIndex }) {
    if (from === to && oldIndex === newIndex) return

    const number = item.dataset.number
    let response
    if (from !== to) {
      response = await this.#patch(this.stateUrlValue, number, { state: to.dataset.state })
    } else {
      const previous = item.previousElementSibling
      const next = item.nextElementSibling
      const body = previous ? { after: previous.dataset.number } : { before: next.dataset.number }
      response = await this.#patch(this.positionUrlValue, number, body)
    }

    if (response.ok) {
      this.errorTarget.textContent = ""
      Turbo.visit(window.location.href, { action: "replace" })
    } else {
      from.insertBefore(item, from.children[oldIndex] || null)
      const { error } = await response.json().catch(() => ({}))
      this.errorTarget.textContent = error || "No se ha podido mover la historia."
    }
  }

  #patch(template, number, body) {
    return fetch(template.replace("__number__", number), {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "X-CSRF-Token": document.querySelector("meta[name=csrf-token]").content
      },
      body: JSON.stringify(body)
    })
  }
}
