import { Controller } from "@hotwired/stimulus"
import Sortable from "sortablejs"

// Tablero: arrastrar entre columnas cambia el estado (Story#move_to!) y
// arrastrar dentro de una columna reordena en el hito (Story#reorder!).
// Si el servidor lo rechaza, la tarjeta vuelve a su sitio y se ve el error.
// En el móvil (< 768px) no se arrastra: hay una pestaña por estado y solo se
// ven las tarjetas de la elegida, que se recuerda mientras dure la sesión.
const mobile = window.matchMedia("(max-width: 767px)")

export default class extends Controller {
  static targets = ["column", "error", "tab", "panel"]
  static values = { sortable: Boolean, stateUrl: String, positionUrl: String, tabKey: String }

  connect() {
    // Al abrir y tras cada repintado en directo (morph, MT-38), que trae la pestaña por defecto.
    this.restore = () => {
      const remembered = this.#storage("get")
      if (remembered && this.tabTargets.some((tab) => tab.dataset.state === remembered)) this.#show(remembered)
    }
    this.restore()
    document.addEventListener("turbo:morph", this.restore)

    this.toggleDragging = () => this.columnTargets.forEach((column) => column.sortable?.option("disabled", mobile.matches))
    mobile.addEventListener("change", this.toggleDragging)
  }

  disconnect() {
    mobile.removeEventListener("change", this.toggleDragging)
    document.removeEventListener("turbo:morph", this.restore)
  }

  select({ currentTarget }) {
    this.#show(currentTarget.dataset.state)
    this.#storage("set", currentTarget.dataset.state)
  }

  columnTargetConnected(column) {
    column.sortable = Sortable.create(column, {
      disabled: mobile.matches,
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

  #show(state) {
    this.tabTargets.forEach((tab) => tab.setAttribute("aria-selected", tab.dataset.state === state))
    this.panelTargets.forEach((panel) => panel.classList.toggle("max-md:hidden", panel.dataset.state !== state))
  }

  // sessionStorage puede fallar (navegación privada): entonces no se recuerda.
  #storage(action, value) {
    try {
      return action === "get" ? sessionStorage.getItem(this.tabKeyValue) : sessionStorage.setItem(this.tabKeyValue, value)
    } catch {
      return null
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
