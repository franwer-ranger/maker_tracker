import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['position']

  connect() {
    console.log('Hello, from project!')
  }

  submit(event) {
    event.preventDefault()
    this.pointsTarget.value = event.target.dataset.points
    this.formTarget.requestSubmit()
  }
}
