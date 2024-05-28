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

  connect() {
    console.log('item connected')
  }

  changePosition(newPosition) {
    this.positionTarget.value = newPosition
  }

  moveToBacklog() {
    this.sprintIdTarget.value = null
    this.iceboxTarget.value = false
  }

  moveToIcebox() {
    this.sprintIdTarget.value = null
    this.iceboxTarget.value = true
  }

  start(userId, sprintId) {
    this.statusTarget.value = 'started'
    this.userIdTarget.value = userId
    this.sprintIdTarget.value = sprintId
    this.iceboxTarget.value = false
    this.positionTarget.value = null
    this.positionChangedTarget.value = 'true'
  }

  apply() {
    this.formTarget.requestSubmit()
  }

  changePoints(event) {
    event.preventDefault()
    const points = event.target.dataset.points
    this.pointsTarget.value = points
    this.formTarget.requestSubmit()
  }
}
