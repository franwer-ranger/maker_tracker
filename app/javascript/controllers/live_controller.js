import { Controller } from "@hotwired/stimulus"

// En directo (MT-38): va en el <turbo-cable-stream-source> de layouts/_live.
// Cuando un agente escribe o cambia su presencia llega un `refresh` y la página
// se vuelve a pintar con morph. Lo que la persona está haciendo no se pierde:
// - Con trabajo sin enviar (un campo con texto, una casilla marcada, un select
//   cambiado: lo que difiere de su valor inicial) o mientras se arrastra o hay
//   un orden sin guardar (`data-live-hold`, el Roadmap), el refresco se aplaza.
//   Se aplica al volver a dejarlo todo como estaba; si se envía, la página ya
//   se pinta entera con el envío.
// - En el repintado (no en los de la propia persona, como el que sigue a un
//   formulario) se conservan el valor, `checked` y `selected` de lo que se ha
//   tocado o tiene el foco, y los <details> siguen plegados o desplegados.
// El markdown y la pestaña del Tablero se vuelven a aplicar en turbo:morph.
export default class extends Controller {
  connect() {
    this.refreshing = false
    this.deferred = false
    this.hold = (event) => {
      if (event.target.getAttribute("action") !== "refresh") return
      if (this.#busy()) {
        event.detail.render = () => {}
        this.deferred = true
      } else {
        // Las mismas condiciones con las que Turbo descarta el refresco (session.refresh):
        // el eco de un cambio de esta pestaña o una visita ya en marcha.
        const { session } = window.Turbo
        const requestId = event.target.getAttribute("request-id")
        this.refreshing = !(requestId && session.recentRequests.has(requestId)) && !session.navigator.currentVisit
      }
    }
    this.keepState = (event) => {
      if (!this.refreshing) return

      const { attributeName } = event.detail
      const element = event.target
      if (["value", "checked", "selected"].includes(attributeName) && (element === document.activeElement || this.#changed(element))) event.preventDefault()
      if (attributeName === "open" && element.tagName === "DETAILS") event.preventDefault()
    }
    // Se ha vuelto a dejar todo como estaba: llega el refresco aplazado.
    this.resume = () => {
      if (!this.deferred || this.#busy()) return

      this.deferred = false
      this.refreshing = true
      window.Turbo.session.refresh(document.baseURI)
    }
    this.done = () => { this.refreshing = false; this.deferred = false }
    document.addEventListener("turbo:before-stream-render", this.hold)
    document.addEventListener("turbo:before-morph-attribute", this.keepState)
    document.addEventListener("input", this.resume)
    document.addEventListener("change", this.resume)
    document.addEventListener("turbo:load", this.done)
  }

  disconnect() {
    document.removeEventListener("turbo:before-stream-render", this.hold)
    document.removeEventListener("turbo:before-morph-attribute", this.keepState)
    document.removeEventListener("input", this.resume)
    document.removeEventListener("change", this.resume)
    document.removeEventListener("turbo:load", this.done)
  }

  #busy() {
    return !!document.querySelector(".sortable-chosen, [data-live-hold]") ||
      [...document.querySelectorAll("input, textarea, select")].some((element) => this.#changed(element))
  }

  // Difiere de lo que trajo el servidor: es trabajo de la persona.
  #changed(element) {
    if (element instanceof HTMLOptionElement) return !!element.parentElement?.closest("select") && this.#changed(element.parentElement.closest("select"))
    if (element instanceof HTMLSelectElement) {
      const options = [...element.options]
      if (element.multiple) return options.some((option) => option.selected !== option.defaultSelected)
      const initial = options.findIndex((option) => option.defaultSelected) // sin ninguna marcada, la primera
      return element.selectedIndex !== Math.max(initial, 0)
    }
    if (element instanceof HTMLTextAreaElement) return element.value !== element.defaultValue
    if (!(element instanceof HTMLInputElement)) return false
    if (["checkbox", "radio"].includes(element.type)) return element.checked !== element.defaultChecked
    if (["hidden", "submit", "button", "reset", "file", "image"].includes(element.type)) return false
    return element.value !== element.defaultValue
  }
}
