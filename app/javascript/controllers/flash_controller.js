import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.timeout = setTimeout(() => this.dismiss(), 5000)

    // Pause auto-dismiss on hover/focus
    this.element.addEventListener("mouseenter", this.#pause)
    this.element.addEventListener("mouseleave", this.#resume)
    this.element.addEventListener("focusin", this.#pause)
    this.element.addEventListener("focusout", this.#resume)
  }

  disconnect() {
    clearTimeout(this.timeout)
    this.element.removeEventListener("mouseenter", this.#pause)
    this.element.removeEventListener("mouseleave", this.#resume)
    this.element.removeEventListener("focusin", this.#pause)
    this.element.removeEventListener("focusout", this.#resume)
  }

  dismiss() {
    clearTimeout(this.timeout)

    const el = this.element
    const height = el.offsetHeight
    const marginBottom = parseInt(getComputedStyle(el).marginBottom, 10)

    // Phase 1: Fade out and slide up
    el.style.transition = "opacity 0.2s ease-out, transform 0.2s ease-out"
    el.style.opacity = "0"
    el.style.transform = "translateY(-8px)"

    // Phase 2: Collapse height smoothly
    setTimeout(() => {
      el.style.transition = "max-height 0.2s ease-out, margin 0.2s ease-out, padding 0.2s ease-out, border-width 0.2s ease-out"
      el.style.maxHeight = height + "px"
      el.style.overflow = "hidden"

      // Force layout to register the maxHeight before animating
      el.offsetHeight
      el.style.maxHeight = "0"
      el.style.marginTop = "0"
      el.style.marginBottom = "0"
      el.style.paddingTop = "0"
      el.style.paddingBottom = "0"
      el.style.borderWidth = "0"

      setTimeout(() => el.remove(), 200)
    }, 200)
  }

  #pause = () => {
    clearTimeout(this.timeout)
  }

  #resume = () => {
    this.timeout = setTimeout(() => this.dismiss(), 3000)
  }
}
