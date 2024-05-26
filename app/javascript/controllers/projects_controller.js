import { Controller } from '@hotwired/stimulus'
import Sortable from 'sortablejs'

export default class extends Controller {
  static targets = ['position', 'items', 'form']

  connect() {
    this.initSortable()
  }

  initSortable() {
    this.itemsTargets.forEach((itemTarget) => {
      if (!itemTarget) return
      this.sortable = new Sortable(itemTarget, {
        group: 'lists',
        onEnd: this.end.bind(this)
      })
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
