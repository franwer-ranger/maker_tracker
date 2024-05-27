import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['form', 'points']

  connect() {}

  submit(event) {
    event.preventDefault()
    this.pointsTarget.value = event.target.dataset.points
    this.formTarget.requestSubmit()
  }
}
