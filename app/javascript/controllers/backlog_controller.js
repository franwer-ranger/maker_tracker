import { Controller } from '@hotwired/stimulus'
import Sortable from 'sortablejs'

export default class extends Controller {
  static outlets = ['items']

  connect() {
    this.sortable = new Sortable(this.element, {
      group: 'sharedList',
      onEnd: this.end.bind(this)
    })
  }

  end(event) {
    const itemOutlet = this.itemsOutlets.find(
      (item) => item.element === event.item
    )
    itemOutlet?.changePosition(event.newIndex + 1)

    if (event.to.dataset.list === 'icebox') itemOutlet?.moveToIcebox()
    itemOutlet?.apply()
  }
}
