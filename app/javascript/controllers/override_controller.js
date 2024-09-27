import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['form']
  connect() {
    console.log('Hello, from override!')
  }

  toggle() {
    this.formTarget.classList.toggle('hidden')
  }
}
