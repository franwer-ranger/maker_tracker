import { Controller } from '@hotwired/stimulus'
import Sortable from 'sortablejs'

export default class extends Controller {
  static outlets = ['items']

  initialize() {
    this.sortable = new Sortable(this.element, {
      group: 'sharedList',
      onEnd: this.end.bind(this),
      onMove: this.#cancelItemForm.bind(this)
    })
  }

  end(event) {
    if (this.#cancelItemForm(event) === false) return false

    const itemOutlet = this.itemsOutlets.find(
      (item) => item.element === event.item
    )
    itemOutlet?.changePosition(event.newIndex + 1)

    if (event.to.dataset.list === 'icebox') itemOutlet?.moveToIcebox()
    itemOutlet?.apply()
  }

  #cancelItemForm(event) {
    const element = event.dragged ?? event.item
    if (element.querySelectorAll('#item-form').length > 0) return false
  }
}
