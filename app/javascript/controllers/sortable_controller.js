import { Controller } from '@hotwired/stimulus'
import Sortable from 'sortablejs'

export default class extends Controller {
  static outlets = ['items']
  initialize() {
    const options = {
      onEnd: this.end.bind(this),
      onMove: this.#cancelItemForm.bind(this)
    }
    const group = this._group()
    if (group != -1) options.group = group

    this.sortable = new Sortable(this.element, options)
  }

  end(event) {
    if (this.#cancelItemForm(event) === false) return false

    const itemOutlet = this.itemsOutlets.find(
      (item) => item.element === event.item
    )
    itemOutlet?.changePosition(event.newIndex + 1)
    return itemOutlet
  }

  #cancelItemForm(event) {
    const element = event.dragged ?? event.item
    if (element.querySelectorAll('#item-form').length > 0) return false
  }

  _group() {
    return -1
  }
}
