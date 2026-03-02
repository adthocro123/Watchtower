import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["item", "list"]

  connect() {
    this.draggedItem = null
    this.#enableDragging()
  }

  dragstart(event) {
    this.draggedItem = event.currentTarget
    event.currentTarget.classList.add("opacity-50")
    event.dataTransfer.effectAllowed = "move"
    event.dataTransfer.setData("text/plain", event.currentTarget.dataset.sortableId)
  }

  dragover(event) {
    event.preventDefault()
    event.dataTransfer.dropEffect = "move"

    const target = event.target.closest("[data-sortable-target='item']")
    if (!target || target === this.draggedItem) return

    const list = this.hasListTarget ? this.listTarget : this.element
    const items = [...list.querySelectorAll("[data-sortable-target='item']")]
    const draggedIndex = items.indexOf(this.draggedItem)
    const targetIndex = items.indexOf(target)

    if (draggedIndex < targetIndex) {
      target.after(this.draggedItem)
    } else {
      target.before(this.draggedItem)
    }
  }

  drop(event) {
    event.preventDefault()
    this.#saveOrder()
  }

  dragend(event) {
    event.currentTarget.classList.remove("opacity-50")
    this.draggedItem = null
  }

  // --- Private ---

  #enableDragging() {
    this.itemTargets.forEach(item => {
      item.setAttribute("draggable", "true")
    })
  }

  #saveOrder() {
    const list = this.hasListTarget ? this.listTarget : this.element
    const items = [...list.querySelectorAll("[data-sortable-target='item']")]
    const orderedIds = items.map(item => item.dataset.sortableId)

    // Update hidden field if present
    const hiddenField = this.element.querySelector("[data-sortable-order]")
    if (hiddenField) {
      hiddenField.value = JSON.stringify(orderedIds)
    }

    // Auto-save via PATCH if a save URL is configured
    const url = this.element.dataset.sortableSaveUrl
    if (!url) return

    const csrfToken = document.querySelector("meta[name='csrf-token']")?.content

    fetch(url, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": csrfToken || "",
        "Accept": "application/json"
      },
      body: JSON.stringify({ entries: orderedIds })
    }).catch(error => {
      console.error("[ScoutRail] Failed to save sort order:", error)
    })
  }
}
