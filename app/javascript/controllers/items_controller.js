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
    'inProgress',
    'done'
  ]

  changePosition(newPosition) {
    this.positionTarget.value = newPosition
  }

  moveToBacklog() {
    this.sprintIdTarget.value = null
    this.iceboxTarget.value = false
    this.inProgressTarget.value = false
    this.doneTarget.value = false
  }

  moveToIcebox() {
    this.sprintIdTarget.value = null
    this.statusTarget.value = 'unstarted'
    this.iceboxTarget.value = true
    this.inProgressTarget.value = false
    this.doneTarget.value = false
  }

  start() {
    this.statusTarget.value = 'started'
    this.userIdTarget.value = this.#userId()
    this.sprintIdTarget.value = this.#sprintId()
    this.iceboxTarget.value = false
    this.inProgressTarget.value = true
    this.doneTarget.value = false
    this.positionTarget.value = null
  }

  finish() {
    this.statusTarget.value = 'finished'
    this.inProgressTarget.value = true
    this.doneTarget.value = false
    this.iceboxTarget.value = false
  }

  deliver() {
    this.statusTarget.value = 'delivered'
    this.inProgressTarget.value = true
    this.doneTarget.value = false
    this.iceboxTarget.value = false
  }

  accept(event) {
    event.preventDefault()
    this.statusTarget.value = 'accepted'
    this.inProgressTarget.value = false
    this.doneTarget.value = true
    this.apply()
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
    if (status === 'unstarted') this.start()
    if (status === 'started') this.finish()
    if (status === 'finished') this.deliver()

    this.apply()
  }

  #userId() {
    return document.querySelector('meta[name="current-user-id"]').content
  }

  #sprintId() {
    return document.querySelector('meta[name="current-sprint-id"]').content
  }
}
