import { Controller } from '@hotwired/stimulus'
import Sortable from 'sortablejs'

export default class extends Controller {
  static outlets = ['items']
  initialize() {
    const options = {
      onEnd: this.end.bind(this),
      onMove: this.move.bind(this),
      filter: '.no-sort',
      draggable: '.item'
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

    itemOutlet?.changePosition(this.#filteredPosition(event.newIndex))
    return itemOutlet
  }

  move(event) {
    this.#cancelItemForm(event)
  }

  #filterPositions() {
    return Array.from(this.element.children)
      .map((item, index) => ({
        element: item,
        position: index + 1
      }))
      .filter((item) => item.element.classList.contains('item'))
      .map((item) => item.position)
  }

  #filteredPosition(index) {
    return this.#filterPositions().indexOf(index + 1) + 1
  }

  #cancelItemForm(event) {
    const element = event.dragged ?? event.item
    if (element.classList.contains('no-sort')) return false
    if (element.querySelectorAll('#item-form').length > 0) return false
  }

  _group() {
    return -1
  }
}
