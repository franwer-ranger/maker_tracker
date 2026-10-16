import { Controller } from "@hotwired/stimulus"

// Envía el formulario en cuanto cambia un control (selector de estado, de hito…).
export default class extends Controller {
  submit() {
    this.element.requestSubmit()
  }
}
