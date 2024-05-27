import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = [
    'form',
    'points',
    'status',
    'userId',
    'sprintId',
    'position',
    'icebox',
    'positionChanged'
  ]
  static values = {
    currentSprintId: Number,
    currentUserId: Number
  }

  connect() {}

  submit(event) {
    event.preventDefault()
    const points = event.target.dataset.points
    const status = event.target.dataset.status

    if (status) {
      if (status === 'unstarted') {
        this.statusTarget.value = 'started'
        this.userIdTarget.value = this.currentUserIdValue
        this.sprintIdTarget.value = this.currentSprintIdValue
        this.iceboxTarget.value = false
        this.positionTarget.value = 1
        this.positionChangedTarget.value = 'true'
      }
    }

    if (points) {
      this.pointsTarget.value = points
    }
    this.formTarget.requestSubmit()
  }
}
