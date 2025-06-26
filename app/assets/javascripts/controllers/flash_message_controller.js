import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["message"]

  dismiss() {
    this.element.remove()
  }

  connect() {
    // Auto-dismiss after 5 seconds for success messages
    if (this.element.dataset.autoDismiss === "true") {
      setTimeout(() => {
        this.dismiss()
      }, 5000)
    }
  }
}