import { Controller } from "@hotwired/stimulus"

// Un campo de una línea que crece con el texto (el título al editar una
// historia, 5.6 · Móvil): Intro envía el formulario, como en un input, en vez
// de saltar de línea. Donde no hay field-sizing, la altura se ajusta a mano.
export default class extends Controller {
  connect() {
    this.manual = !CSS.supports("field-sizing", "content")
    this.resize()
  }

  submit(event) {
    event.preventDefault()
    this.element.form.requestSubmit()
  }

  resize() {
    if (!this.manual) return

    this.element.style.height = "auto"
    this.element.style.height = `${this.element.scrollHeight + 2}px`
  }
}
