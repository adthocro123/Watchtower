import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { key: String }

  connect() {
    if (sessionStorage.getItem(this.keyValue)) {
      this.element.remove()
    }
  }

  dismiss() {
    sessionStorage.setItem(this.keyValue, "1")

    this.element.style.transition = "opacity 0.15s ease-out"
    this.element.style.opacity = "0"

    setTimeout(() => this.element.remove(), 150)
  }
}
