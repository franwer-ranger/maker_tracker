import SortableController from './sortable_controller'

export default class extends SortableController {
  end(event) {
    const itemOutlet = super.end(event)
    if (!itemOutlet) return

    if (event.to.dataset.list === 'icebox') itemOutlet?.moveToIcebox()
    itemOutlet?.apply()
  }

  _group() {
    return 'sharedList'
  }
}
