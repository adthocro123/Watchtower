import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["item", "pickedCount", "toggle", "hidePickedLabel"]
  static values = {
    storageKey: String
  }

  connect() {
    this.hiddenPicked = false
    this.pickedIds = new Set(this.#loadPickedIds())
    this.#applyState()
  }

  toggle(event) {
    const teamId = event.currentTarget.dataset.teamId
    if (!teamId) return

    if (this.pickedIds.has(teamId)) {
      this.pickedIds.delete(teamId)
    } else {
      this.pickedIds.add(teamId)
    }

    this.#persist()
    this.#applyState()
  }

  toggleHidePicked() {
    this.hiddenPicked = !this.hiddenPicked
    this.hidePickedLabelTarget.textContent = this.hiddenPicked ? "Show picked" : "Hide picked"
    this.#applyState()
  }

  #applyState() {
    this.itemTargets.forEach(item => {
      const picked = this.pickedIds.has(item.dataset.sortableId)
      item.classList.toggle("opacity-50", picked)
      item.classList.toggle("bg-emerald-500/5", picked)
      item.classList.toggle("hidden", picked && this.hiddenPicked)

      const toggle = this.toggleTargets.find(button => button.dataset.teamId === item.dataset.sortableId)
      if (toggle) {
        toggle.textContent = picked ? "Picked" : "Mark picked"
        toggle.className = picked
          ? "rounded-lg px-3 py-1.5 text-xs font-semibold bg-emerald-500/20 text-emerald-300 border border-emerald-500/30 transition-colors duration-150"
          : "rounded-lg px-3 py-1.5 text-xs font-semibold bg-gray-800 text-gray-300 border border-gray-700 hover:border-emerald-500/30 hover:text-emerald-300 transition-colors duration-150"
      }
    })

    this.pickedCountTarget.textContent = `${this.pickedIds.size} picked`
  }

  #persist() {
    if (!this.hasStorageKeyValue) return

    try {
      window.localStorage.setItem(this.storageKeyValue, JSON.stringify([...this.pickedIds]))
    } catch (_error) {
      // Ignore storage failures so board actions still work for this session.
    }
  }

  #loadPickedIds() {
    if (!this.hasStorageKeyValue) return []

    try {
      const raw = window.localStorage.getItem(this.storageKeyValue)
      return raw ? JSON.parse(raw) : []
    } catch (_error) {
      return []
    }
  }
}
