import { Controller } from "@hotwired/stimulus"

// Scoring constants matching app/models/concerns/scoring.rb
const FUEL_POINT_VALUE = 1
const AUTON_CLIMB_POINTS = 10
const CLIMB_POINTS = { None: 0, L1: 10, L2: 20, L3: 30 }

export default class extends Controller {
  static targets = [
    "autonMade", "autonMissed",
    "teleopMade", "teleopMissed",
    "endgameMade", "endgameMissed",
    "autonClimb", "endgameClimb",
    "accuracy", "totalPoints", "totalMade", "totalMissed",
    "dataField", "tabContent"
  ]

  static values = {
    autonMade:    { type: Number, default: 0 },
    autonMissed:  { type: Number, default: 0 },
    teleopMade:   { type: Number, default: 0 },
    teleopMissed: { type: Number, default: 0 },
    endgameMade:  { type: Number, default: 0 },
    endgameMissed:{ type: Number, default: 0 },
    autonClimb:   { type: Boolean, default: false },
    endgameClimb: { type: String, default: "None" }
  }

  connect() {
    this.autonActions = []
    this.updateDisplay()
  }

  // --- Counter actions ---

  incrementMade(event) {
    const phase = event.currentTarget.dataset.phase
    this.#incrementValue(phase, "Made")
    this.#haptic()
    this.#pulseElement(event.currentTarget)

    if (phase === "auton") {
      this.#addAutonActionEntry("fuel_made")
    }

    this.updateDisplay()
  }

  incrementMissed(event) {
    const phase = event.currentTarget.dataset.phase
    this.#incrementValue(phase, "Missed")
    this.#haptic()
    this.#pulseElement(event.currentTarget)

    if (phase === "auton") {
      this.#addAutonActionEntry("fuel_missed")
    }

    this.updateDisplay()
  }

  undoMade(event) {
    const phase = event.currentTarget.dataset.phase
    this.#decrementValue(phase, "Made")
    this.#haptic(20)
    this.updateDisplay()
  }

  undoMissed(event) {
    const phase = event.currentTarget.dataset.phase
    this.#decrementValue(phase, "Missed")
    this.#haptic(20)
    this.updateDisplay()
  }

  // --- Climb actions ---

  toggleAutonClimb() {
    this.autonClimbValue = !this.autonClimbValue
    this.#haptic()

    if (this.hasAutonClimbTarget) {
      this.autonClimbTarget.classList.toggle("ring-2", this.autonClimbValue)
      this.autonClimbTarget.classList.toggle("ring-emerald-400", this.autonClimbValue)
      this.autonClimbTarget.classList.toggle("bg-emerald-900/50", this.autonClimbValue)
    }

    if (this.autonClimbValue) {
      this.#addAutonActionEntry("climb")
    }

    this.updateDisplay()
  }

  selectClimb(event) {
    const level = event.currentTarget.dataset.level
    this.endgameClimbValue = level
    this.#haptic()

    // Highlight the selected card, deselect others
    this.element.querySelectorAll("[data-climb-card]").forEach(card => {
      const isSelected = card.dataset.level === level
      card.classList.toggle("ring-2", isSelected)
      card.classList.toggle("ring-emerald-400", isSelected)
      card.classList.toggle("bg-emerald-900/50", isSelected)
      card.classList.toggle("bg-gray-800", !isSelected)
    })

    this.updateDisplay()
  }

  // --- Auton actions timeline ---

  addAutonAction(event) {
    const action = event.currentTarget.dataset.action
    this.#addAutonActionEntry(action)
  }

  // --- Tab switching ---

  switchTab(event) {
    const tab = event.currentTarget.dataset.tab

    // Update tab button styling
    this.element.querySelectorAll("[data-tab-button]").forEach(btn => {
      const isActive = btn.dataset.tab === tab
      btn.classList.toggle("border-emerald-400", isActive)
      btn.classList.toggle("text-emerald-400", isActive)
      btn.classList.toggle("border-transparent", !isActive)
      btn.classList.toggle("text-gray-400", !isActive)
    })

    // Show/hide tab content panels
    this.tabContentTargets.forEach(panel => {
      const isVisible = panel.dataset.tabPanel === tab
      panel.classList.toggle("hidden", !isVisible)
    })
  }

  // --- Form submission ---

  submitForm(event) {
    const payload = this.#buildDataPayload()

    if (this.hasDataFieldTarget) {
      this.dataFieldTarget.value = JSON.stringify(payload)
    }

    // If offline, save to IndexedDB queue and prevent server submission
    if (!navigator.onLine) {
      event.preventDefault()
      this.#saveToOfflineQueue(payload)
    }
  }

  // --- Private helpers ---

  updateDisplay() {
    const made = this.autonMadeValue + this.teleopMadeValue + this.endgameMadeValue
    const missed = this.autonMissedValue + this.teleopMissedValue + this.endgameMissedValue
    const total = made + missed
    const accuracy = total > 0 ? ((made / total) * 100).toFixed(1) : "0.0"

    let points = made * FUEL_POINT_VALUE
    if (this.autonClimbValue) points += AUTON_CLIMB_POINTS
    points += CLIMB_POINTS[this.endgameClimbValue] || 0

    // Update phase counters
    this.#setTargetText("autonMade", this.autonMadeValue)
    this.#setTargetText("autonMissed", this.autonMissedValue)
    this.#setTargetText("teleopMade", this.teleopMadeValue)
    this.#setTargetText("teleopMissed", this.teleopMissedValue)
    this.#setTargetText("endgameMade", this.endgameMadeValue)
    this.#setTargetText("endgameMissed", this.endgameMissedValue)

    // Update totals
    this.#setTargetText("totalMade", made)
    this.#setTargetText("totalMissed", missed)
    this.#setTargetText("accuracy", `${accuracy}%`)
    this.#setTargetText("totalPoints", points)
  }

  #buildDataPayload() {
    return {
      auton_fuel_made: this.autonMadeValue,
      auton_fuel_missed: this.autonMissedValue,
      teleop_fuel_made: this.teleopMadeValue,
      teleop_fuel_missed: this.teleopMissedValue,
      endgame_fuel_made: this.endgameMadeValue,
      endgame_fuel_missed: this.endgameMissedValue,
      auton_climb: this.autonClimbValue,
      endgame_climb: this.endgameClimbValue,
      auton_actions: this.autonActions
    }
  }

  async #saveToOfflineQueue(payload) {
    try {
      const db = await this.#openDB()
      const form = this.element.closest("form")

      const entry = {
        client_uuid: crypto.randomUUID(),
        match_id: form?.querySelector("[name*='match_id']")?.value || null,
        frc_team_id: form?.querySelector("[name*='frc_team_id']")?.value || null,
        event_id: form?.querySelector("[name*='event_id']")?.value || null,
        notes: form?.querySelector("[name*='notes']")?.value || "",
        data: payload,
        created_at: new Date().toISOString()
      }

      const tx = db.transaction("offline_entries", "readwrite")
      tx.objectStore("offline_entries").add(entry)
      await new Promise((resolve, reject) => {
        tx.oncomplete = resolve
        tx.onerror = () => reject(tx.error)
      })

      db.close()

      // Notify the user
      this.#showOfflineConfirmation()
    } catch (error) {
      console.error("[ScoutRail] Failed to save offline entry:", error)
      alert("Failed to save entry offline. Please try again.")
    }
  }

  #openDB() {
    return new Promise((resolve, reject) => {
      const request = indexedDB.open("scoutrail", 1)
      request.onupgradeneeded = (event) => {
        const db = event.target.result
        if (!db.objectStoreNames.contains("offline_entries")) {
          db.createObjectStore("offline_entries", { keyPath: "client_uuid" })
        }
      }
      request.onsuccess = () => resolve(request.result)
      request.onerror = () => reject(request.error)
    })
  }

  #showOfflineConfirmation() {
    const banner = document.createElement("div")
    banner.className = "fixed top-4 left-1/2 -translate-x-1/2 z-50 bg-amber-600 text-white px-6 py-3 rounded-lg shadow-lg font-medium"
    banner.textContent = "Entry saved offline. It will sync when you reconnect."
    document.body.appendChild(banner)

    setTimeout(() => {
      banner.style.transition = "opacity 0.5s"
      banner.style.opacity = "0"
      setTimeout(() => banner.remove(), 500)
    }, 3000)
  }

  #incrementValue(phase, suffix) {
    const key = `${phase}${suffix}Value`
    this[key] = this[key] + 1
  }

  #decrementValue(phase, suffix) {
    const key = `${phase}${suffix}Value`
    this[key] = Math.max(0, this[key] - 1)
  }

  #addAutonActionEntry(action) {
    this.autonActions.push({
      action: action,
      timestamp: Date.now()
    })
  }

  #setTargetText(name, value) {
    const targetName = `${name}Target`
    if (this[`has${name.charAt(0).toUpperCase() + name.slice(1)}Target`]) {
      this[targetName].textContent = value
    }
  }

  #haptic(duration = 30) {
    if (navigator.vibrate) {
      navigator.vibrate(duration)
    }
  }

  #pulseElement(el) {
    el.classList.add("scale-110")
    setTimeout(() => el.classList.remove("scale-110"), 120)
  }
}
