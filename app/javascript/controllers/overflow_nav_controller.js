import { Controller } from "@hotwired/stimulus"

// Dynamically fits as many nav items as possible into a bottom nav bar,
// moving the rest into a "More" overflow menu. Uses ResizeObserver to
// re-layout on resize.
export default class extends Controller {
  static targets = ["item", "moreButton", "menu", "menuItem"]

  connect() {
    // Close the menu when tapping outside
    this._onClickOutside = (e) => {
      if (this.hasMoreButtonTarget && !this.moreButtonTarget.contains(e.target)) {
        this.moreButtonTarget.removeAttribute("open")
      }
    }
    document.addEventListener("click", this._onClickOutside)

    this._itemWidths = null

    this._observer = new ResizeObserver(() => this.layout())
    this._observer.observe(this.element)

    // Initial layout after a frame so widths are painted
    requestAnimationFrame(() => this.layout())
  }

  disconnect() {
    this._observer?.disconnect()
    document.removeEventListener("click", this._onClickOutside)
  }

  layout() {
    const items = this.itemTargets
    const menuItems = this.menuItemTargets
    if (items.length === 0) return

    // Measure item widths once. We temporarily switch to a tight layout so
    // we get the intrinsic width of each item without justify-around gaps.
    if (!this._itemWidths) {
      this._itemWidths = []

      // Show all items + More for measuring
      items.forEach((el) => el.classList.remove("hidden"))
      this.moreButtonTarget.classList.remove("hidden")

      // Temporarily remove justify-around so items pack tightly
      const origJustify = this.element.style.justifyContent
      this.element.style.justifyContent = "flex-start"

      // Force layout recalc
      this.element.offsetHeight // eslint-disable-line no-unused-expressions

      for (const item of items) {
        // Use getBoundingClientRect for sub-pixel accuracy
        this._itemWidths.push(Math.ceil(item.getBoundingClientRect().width))
      }
      this._moreWidth = Math.ceil(this.moreButtonTarget.getBoundingClientRect().width)

      // Restore layout
      this.element.style.justifyContent = origJustify
    }

    const containerWidth = this.element.clientWidth
    // Add a per-item gap estimate. With justify-around on N items, total gap
    // space is roughly containerWidth - sum(item widths). But we're deciding
    // how many items to show, so we use a small fixed per-item spacing buffer
    // to avoid edge cases where items just barely "fit" but get cramped.
    const GAP = 4 // px buffer per item
    const moreWidth = this._moreWidth
    let totalWidth = 0
    let fitCount = 0

    // First pass: can everything fit without the More button?
    for (let i = 0; i < items.length; i++) {
      totalWidth += this._itemWidths[i] + GAP
      if (totalWidth > containerWidth) break
      fitCount = i + 1
    }

    if (fitCount === items.length) {
      // Everything fits — hide More, show all items, hide all menu items
      items.forEach((el) => el.classList.remove("hidden"))
      menuItems.forEach((el) => el.classList.add("hidden"))
      this.moreButtonTarget.classList.add("hidden")
      this.moreButtonTarget.removeAttribute("open")
      return
    }

    // Need the More button — recalculate with its width reserved
    totalWidth = 0
    fitCount = 0
    for (let i = 0; i < items.length; i++) {
      totalWidth += this._itemWidths[i] + GAP
      if (totalWidth + moreWidth + GAP > containerWidth) break
      fitCount = i + 1
    }

    // Ensure at least 2 items show in the bar (Home + Scout minimum)
    fitCount = Math.max(fitCount, Math.min(2, items.length))

    // Show/hide bar items and their corresponding menu items
    items.forEach((el, i) => {
      el.classList.toggle("hidden", i >= fitCount)
    })
    menuItems.forEach((el, i) => {
      el.classList.toggle("hidden", i < fitCount)
    })

    this.moreButtonTarget.classList.remove("hidden")
  }
}
