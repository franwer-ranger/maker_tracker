import { Controller } from '@hotwired/stimulus'
import { marked } from 'marked'
import DOMPurify from 'dompurify'

export default class extends Controller {
  static targets = ['preview', 'field', 'content', 'markdown']
  static values = {
    content: String
  }

  connect() {
    this.#render()
  }

  toggle() {
    this.previewTarget.classList.toggle('hidden')
    this.fieldTarget.classList.toggle('hidden')
  }

  change(event) {
    this.contentValue = event.target.value
    this.#render()
  }

  #render() {
    const markdown = DOMPurify.sanitize(marked.parse(this.contentValue))
    this.markdownTarget.innerHTML = markdown
  }
}
