import { Controller } from "@hotwired/stimulus"
import Sortable from "sortablejs"

// Roadmap: arrastrar hitos (Milestone#reorder!) e historias, dentro de su hito,
// a otro o a la bandeja (Story#reorder!). Al soltar no se guarda todavía: se
// pide un motivo opcional, porque el evento no se puede editar después.
// En el móvil (< 768px) no se arrastra: el orden se cambia en el escritorio o con `mt reorder`.
const mobile = window.matchMedia("(max-width: 767px)")

export default class extends Controller {
  static targets = ["milestones", "stories", "pending", "pendingLabel", "reason", "error"]
  static values = { milestoneUrl: String, storyUrl: String }

  connect() {
    this.toggleDragging = () => this.#sortables().forEach((sortable) => sortable.option("disabled", mobile.matches))
    mobile.addEventListener("change", this.toggleDragging)
  }

  disconnect() {
    mobile.removeEventListener("change", this.toggleDragging)
  }

  milestonesTargetConnected(list) {
    list.sortable = Sortable.create(list, {
      disabled: mobile.matches,
      handle: "[data-handle]",
      animation: 150,
      easing: "cubic-bezier(0.32, 0.72, 0, 1)",
      ghostClass: "opacity-40",
      onEnd: (event) => {
        this.#mountStories()
        this.#dropped(event, this.milestoneUrlValue, "id", "Nuevo orden de hitos sin guardar")
      }
    })
  }

  storiesTargetConnected(list) {
    if (list.sortable) return

    list.sortable = Sortable.create(list, {
      disabled: mobile.matches,
      group: "roadmap-stories",
      animation: 150,
      easing: "cubic-bezier(0.32, 0.72, 0, 1)",
      ghostClass: "opacity-40",
      onEnd: (event) => this.#dropped(event, this.storyUrlValue, "number", "Nuevo orden sin guardar")
    })
  }

  milestonesTargetDisconnected(list) { list.sortable?.destroy() }
  storiesTargetDisconnected(list) {
    list.sortable?.destroy()
    list.sortable = null
  }

  // Las listas de historias anidadas interfieren con el arrastre de un hito:
  // al pulsar su asa (pointerdown, antes de que Sortable empiece) se desmontan,
  // y se vuelven a montar al soltar. Desmontarlas después cancelaría el arrastre.
  suspendStories() {
    this.storiesTargets.forEach((list) => this.storiesTargetDisconnected(list))
    document.addEventListener("pointerup", () => this.#mountStories(), { once: true })
  }

  // El asa de un hito está dentro de su <summary>: pulsarla no lo pliega.
  preventToggle(event) {
    event.preventDefault()
  }

  async save() {
    if (!this.change) return

    const { url, body } = this.change
    const response = await fetch(url, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "X-CSRF-Token": document.querySelector("meta[name=csrf-token]").content
      },
      body: JSON.stringify({ ...body, reason: this.reasonTarget.value })
    })

    if (response.ok) {
      this.change = null
      Turbo.visit(window.location.href, { action: "replace" })
    } else {
      const { error } = await response.json().catch(() => ({}))
      this.errorTarget.textContent = error || "No se ha podido guardar el orden."
    }
  }

  discard() {
    this.change = null
    Turbo.visit(window.location.href, { action: "replace" })
  }

  #sortables() {
    return [...this.milestonesTargets, ...this.storiesTargets].map((list) => list.sortable).filter(Boolean)
  }

  #mountStories() {
    this.storiesTargets.forEach((list) => this.storiesTargetConnected(list))
  }

  #dropped({ item, from, to, oldIndex, newIndex }, template, key, label) {
    if (from === to && oldIndex === newIndex) return

    // Un cambio cada vez: si ya había uno pendiente, se descarta y se recarga.
    if (this.change) return this.discard()

    const previous = item.previousElementSibling
    const next = item.nextElementSibling
    let body
    if (previous) body = { after: previous.dataset[key] }
    else if (next) body = { before: next.dataset[key] }
    else body = { milestone: to.dataset.milestone }

    this.change = { url: template.replace("__id__", item.dataset[key]), body }
    this.pendingLabelTarget.textContent = label
    this.errorTarget.textContent = ""
    this.reasonTarget.value = ""
    this.pendingTarget.classList.replace("hidden", "flex")
    this.reasonTarget.focus()
  }
}
