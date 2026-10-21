import { Controller } from "@hotwired/stimulus"

// En directo sin repintar la página (MT-38, editar una historia): cada refresco
// del proyecto recarga solo el marco `id`, y el formulario no se toca.
export default class extends Controller {
  static values = { id: String }

  connect() {
    this.reload = (event) => {
      if (event.target.getAttribute("action") !== "refresh") return

      event.detail.render = () => document.getElementById(this.idValue)?.reload() // trae otra vez su `src`
    }
    document.addEventListener("turbo:before-stream-render", this.reload)
  }

  disconnect() {
    document.removeEventListener("turbo:before-stream-render", this.reload)
  }
}
