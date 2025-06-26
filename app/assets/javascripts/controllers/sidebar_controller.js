import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="sidebar"
export default class extends Controller {
  static targets = ["button", "menu", "icon"]

  toggle(event) {
    const button = event.currentTarget
    const menuId = button.getAttribute('aria-controls')
    const menu = document.getElementById(menuId)
    const icon = button.querySelector('.fa-caret-down')

    if (menu) {
      const isExpanded = button.getAttribute('aria-expanded') === 'true'

      if (isExpanded) {
        // Collapse
        button.setAttribute('aria-expanded', 'false')
        menu.classList.remove('max-h-96', 'opacity-100')
        menu.classList.add('max-h-0', 'opacity-0')
        icon.classList.remove('rotate-180')
      } else {
        // Expand
        button.setAttribute('aria-expanded', 'true')
        menu.classList.remove('max-h-0', 'opacity-0')
        menu.classList.add('max-h-96', 'opacity-100')
        icon.classList.add('rotate-180')
      }
    }
  }

  expandAll() {
    this.buttonTargets.forEach(button => {
      const menuId = button.getAttribute('aria-controls')
      const menu = document.getElementById(menuId)
      const icon = button.querySelector('.fa-caret-down')

      if (menu) {
        button.setAttribute('aria-expanded', 'true')
        menu.classList.remove('max-h-0', 'opacity-0')
        menu.classList.add('max-h-96', 'opacity-100')
        icon.classList.add('rotate-180')
      }
    })
  }

  collapseAll() {
    this.buttonTargets.forEach(button => {
      const menuId = button.getAttribute('aria-controls')
      const menu = document.getElementById(menuId)
      const icon = button.querySelector('.fa-caret-down')

      if (menu) {
        button.setAttribute('aria-expanded', 'false')
        menu.classList.remove('max-h-96', 'opacity-100')
        menu.classList.add('max-h-0', 'opacity-0')
        icon.classList.remove('rotate-180')
      }
    })
  }
}