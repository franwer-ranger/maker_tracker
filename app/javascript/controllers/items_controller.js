import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = [
    'form',
    'points',
    'status',
    'userId',
    'sprintId',
    'position',
    'icebox'
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

  start() {
    this.statusTarget.value = 'started'
    this.userIdTarget.value = this.#userId()
    this.sprintIdTarget.value = this.#sprintId()
    this.iceboxTarget.value = false
    this.positionTarget.value = null
  }

  apply() {
    this.formTarget.requestSubmit()
  }

  changePoints(event) {
    event.preventDefault()
    const points = event.target.dataset.points
    this.pointsTarget.value = points
    this.apply()
  }

  changeStatus(event) {
    event.preventDefault()
    const status = event.target.dataset.status
    if (status === 'unstarted') this.start(null, null)

    this.apply()
  }

  #userId() {
    return document.querySelector('meta[name="current-user-id"]').content
  }

  #sprintId() {
    return document.querySelector('meta[name="current-sprint-id"]').content
  }
}
