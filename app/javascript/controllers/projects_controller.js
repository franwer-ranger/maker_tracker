import { Controller } from '@hotwired/stimulus'
import Sortable from 'sortablejs'

export default class extends Controller {
  static targets = [
    'position',
    'items',
    'form',
    'icebox',
    'sprintId',
    'userId',
    'status'
  ]

  static values = {
    currentSprintId: Number,
    currentUserId: Number
  }

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

  changeStatus(event) {
    event.preventDefault()

    this.formTarget.action = this.formTarget.action.replace(
      ':item',
      event.target.dataset.itemId
    )

    const status = event.target.dataset.status
    if (status === 'unstarted') {
      this.statusTarget.value = 'started'
      this.userIdTarget.value = this.currentUserIdValue
      this.sprintIdTarget.value = this.currentSprintIdValue
      this.iceboxTarget.value = false
      this.positionTarget.value = 1
    }

    this.formTarget.requestSubmit()
  }
}
