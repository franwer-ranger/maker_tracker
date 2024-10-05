import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['itemForm', 'itemStateForm', 'points', 'state', 'position']

  changePosition(newPosition) {
    this.positionTarget.value = newPosition
    this.itemFormTarget.requestSubmit()
  }

  moveToBacklog() {
    this.stateTarget.value = 'to_backlog'
    this.itemStateFormTarget.requestSubmit()
  }

  moveToIcebox() {
    this.stateTarget.value = 'to_icebox'
    this.itemStateFormTarget.requestSubmit()
  }

  accept(event) {
    event.preventDefault()
    this.stateTarget.value = 'accepted'
    this.itemStateFormTarget.requestSubmit()
  }

  changePoints(event) {
    event.preventDefault()
    this.pointsTarget.value = event.target.dataset.points
    this.itemFormTarget.requestSubmit()
  }

  changeStatus(event) {
    event.preventDefault()
    this.stateTarget.value = event.target.dataset.status
    this.itemStateFormTarget.requestSubmit()
  }
}
