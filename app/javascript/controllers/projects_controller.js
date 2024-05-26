import { Controller } from '@hotwired/stimulus'
import Sortable from 'sortablejs'

export default class extends Controller {
  static targets = ['position', 'icebox', 'form']

  connect() {
    this.initSortable()
  }

  initSortable() {
    if (!this.hasIceboxTarget) return
    this.sortable = new Sortable(this.iceboxTarget, {
      group: 'lists',
      onEnd: this.end.bind(this)
    })
  }

  end(event) {
    this.formTarget.action = this.formTarget.action.replace(
      ':item',
      event.item.dataset.itemId
    )
    this.positionTarget.value = event.newIndex + 1
    this.formTarget.requestSubmit()
  }
}
