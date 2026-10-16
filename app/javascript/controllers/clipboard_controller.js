import { Controller } from "@hotwired/stimulus"

// Copia el texto de un bloque (p. ej. el terminal) al portapapeles.
export default class extends Controller {
  static targets = ["source"]

  copy() {
    navigator.clipboard.writeText(this.sourceTarget.innerText.trim())
  }
}
