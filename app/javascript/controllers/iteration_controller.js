import SortableController from './sortable_controller'

export default class extends SortableController {
  end(event) {
    const itemOutlet = super.end(event)
    itemOutlet?.apply()
  }
}
