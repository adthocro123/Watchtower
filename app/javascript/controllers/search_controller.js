import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "item"]

  filter() {
    const query = this.inputTarget.value.toLowerCase().trim()

    this.itemTargets.forEach(item => {
      const searchText = (item.dataset.search || item.textContent).toLowerCase()
      const matches = query === "" || searchText.includes(query)
      item.classList.toggle("hidden", !matches)
    })
  }
}
