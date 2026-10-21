import { Controller } from "@hotwired/stimulus"

// En directo (MT-38): va en el <turbo-cable-stream-source> de layouts/_live.
// Cuando un agente escribe o cambia su presencia llega un `refresh` y la página
// se vuelve a pintar con morph. En ese repintado (no en los de la propia
// persona, como el que sigue a un formulario) se cuida lo que está haciendo:
// - no se pisa el texto del campo que tiene el foco (p. ej. un comentario a medias);
// - lo plegado o desplegado (<details>: menús, hitos del Roadmap) sigue como estaba;
// - no se repinta mientras se arrastra o hay un cambio sin guardar
//   (`data-live-hold`, el orden del Roadmap): se pierde ese refresco y llega el siguiente.
// El markdown y la pestaña del Tablero se vuelven a aplicar en turbo:morph.
export default class extends Controller {
  connect() {
    this.refreshing = false
    this.hold = (event) => {
      if (event.target.getAttribute("action") !== "refresh") return
      if (document.querySelector(".sortable-chosen, [data-live-hold]")) {
        event.detail.render = () => {}
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
      if (attributeName === "value" && event.target === document.activeElement) event.preventDefault()
      if (attributeName === "open" && event.target.tagName === "DETAILS") event.preventDefault()
    }
    this.done = () => { this.refreshing = false }
    document.addEventListener("turbo:before-stream-render", this.hold)
    document.addEventListener("turbo:before-morph-attribute", this.keepState)
    document.addEventListener("turbo:load", this.done)
  }

  disconnect() {
    document.removeEventListener("turbo:before-stream-render", this.hold)
    document.removeEventListener("turbo:before-morph-attribute", this.keepState)
    document.removeEventListener("turbo:load", this.done)
  }
}
