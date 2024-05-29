import { Controller } from '@hotwired/stimulus'
import Sortable from 'sortablejs'

export default class extends Controller {
  static outlets = ['items']

  initialize() {
    this.sortable = new Sortable(this.element, {
      filter: '.item-form',
      onEnd: this.end.bind(this)
    })
  }

  end(event) {
    const itemOutlet = this.itemsOutlets.find(
      (item) => item.element === event.item
    )
    itemOutlet?.changePosition(event.newIndex + 1)
    itemOutlet?.apply()
  }
}
