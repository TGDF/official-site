import { Controller } from "@hotwired/stimulus"

export default class NavbarController extends Controller<HTMLFormElement> {
  static targets = ['collapse']
  declare readonly collapseTarget: HTMLInputElement
  declare readonly hasCollapseTarget: boolean

  get isCollapsed(): boolean {
    return this.collapseTarget.classList.contains('hidden')
  }

  open() {
    this.collapseTarget.classList.remove('hidden')
  }

  close() {
    this.collapseTarget.classList.add('hidden')
  }

  toggle(evt) {
    evt.preventDefault()

    if(!this.hasCollapseTarget) {
      return
    }

    if (this.isCollapsed) {
      this.open()
    } else {
      this.close()
    }
  }
}
