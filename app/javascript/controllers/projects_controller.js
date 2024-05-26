import { Controller } from '@hotwired/stimulus'
import Sortable from 'sortablejs'

export default class extends Controller {
  static targets = ['position', 'items', 'form', 'icebox', 'sprintId']

  connect() {
    this.initSortable()
    console.log('Icebox', this.iceboxTarget)
    console.log('SprintId', this.sprintIdTarget)
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
    const toList = event.to.dataset.list

    if (toList === 'icebox') {
      this.sprintIdTarget.value = null
      this.iceboxTarget.value = true
    }

    if (toList === 'backlog') {
      this.sprintIdTarget.value = event.to.dataset.sprintId
      this.iceboxTarget.value = false
    }

    this.positionTarget.value = event.newIndex + 1
    this.formTarget.requestSubmit()
  }
}
