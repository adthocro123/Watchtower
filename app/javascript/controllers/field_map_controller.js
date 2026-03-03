import { Controller } from "@hotwired/stimulus"

// Stimulus controller for drawing auton paths on the field map.
// Stores strokes as normalized (0-1) coordinates in the hidden field
// so they can be re-rendered at any resolution.
export default class extends Controller {
  static targets = ["canvas", "image", "hiddenField"]
  static values = { strokes: { type: Array, default: [] }, readonly: { type: Boolean, default: false } }

  connect() {
    this.currentStroke = null
    this.strokes = [...this.strokesValue]

    // Wait for the image to load so we can size the canvas properly
    if (this.hasImageTarget) {
      if (this.imageTarget.complete) {
        this.#setup()
      } else {
        this.imageTarget.addEventListener("load", () => this.#setup(), { once: true })
      }
    }

    // Re-render on window resize
    this._resizeHandler = () => this.#resize()
    window.addEventListener("resize", this._resizeHandler)
  }

  disconnect() {
    window.removeEventListener("resize", this._resizeHandler)
  }

  // --- Drawing actions ---

  startStroke(event) {
    if (this.readonlyValue) return
    event.preventDefault()
    this.canvasTarget.setPointerCapture(event.pointerId)
    const point = this.#normalizedPoint(event)
    this.currentStroke = [point]
  }

  continueStroke(event) {
    if (!this.currentStroke || this.readonlyValue) return
    event.preventDefault()
    const point = this.#normalizedPoint(event)
    this.currentStroke.push(point)
    this.#render()
  }

  endStroke(event) {
    if (!this.currentStroke || this.readonlyValue) return
    event.preventDefault()

    // Only save strokes with at least 2 points (actual movement)
    if (this.currentStroke.length >= 2) {
      this.strokes.push(this.currentStroke)
      this.#syncHiddenField()
    }
    this.currentStroke = null
    this.#render()
  }

  undo() {
    if (this.strokes.length === 0) return
    this.strokes.pop()
    this.#syncHiddenField()
    this.#render()
  }

  clear() {
    this.strokes = []
    this.currentStroke = null
    this.#syncHiddenField()
    this.#render()
  }

  // --- Private helpers ---

  #setup() {
    this.#resize()
    this.#render()
  }

  #resize() {
    const canvas = this.canvasTarget
    const rect = canvas.getBoundingClientRect()

    // Set canvas internal resolution to match display size (for crisp lines)
    const dpr = window.devicePixelRatio || 1
    canvas.width = rect.width * dpr
    canvas.height = rect.height * dpr

    const ctx = canvas.getContext("2d")
    ctx.scale(dpr, dpr)

    this.displayWidth = rect.width
    this.displayHeight = rect.height

    this.#render()
  }

  #render() {
    const canvas = this.canvasTarget
    const ctx = canvas.getContext("2d")
    const dpr = window.devicePixelRatio || 1

    ctx.clearRect(0, 0, canvas.width / dpr, canvas.height / dpr)

    // Draw saved strokes, alternating orange and black
    const colors = ["#f97316", "#000000"] // orange-500, black
    for (let i = 0; i < this.strokes.length; i++) {
      this.#drawStroke(ctx, this.strokes[i], colors[i % 2], 3)
    }

    // Draw current in-progress stroke in the next color
    if (this.currentStroke && this.currentStroke.length >= 2) {
      const nextColor = colors[this.strokes.length % 2]
      this.#drawStroke(ctx, this.currentStroke, nextColor, 3)
    }
  }

  #drawStroke(ctx, stroke, color, lineWidth) {
    if (stroke.length < 2) return

    ctx.beginPath()
    ctx.strokeStyle = color
    ctx.lineWidth = lineWidth
    ctx.lineCap = "round"
    ctx.lineJoin = "round"

    const first = stroke[0]
    ctx.moveTo(first.x * this.displayWidth, first.y * this.displayHeight)

    for (let i = 1; i < stroke.length; i++) {
      ctx.lineTo(stroke[i].x * this.displayWidth, stroke[i].y * this.displayHeight)
    }
    ctx.stroke()

    // Draw a small circle at the start point
    ctx.beginPath()
    ctx.fillStyle = color
    ctx.arc(first.x * this.displayWidth, first.y * this.displayHeight, 4, 0, Math.PI * 2)
    ctx.fill()
  }

  #normalizedPoint(event) {
    const rect = this.canvasTarget.getBoundingClientRect()
    return {
      x: Math.max(0, Math.min(1, (event.clientX - rect.left) / rect.width)),
      y: Math.max(0, Math.min(1, (event.clientY - rect.top) / rect.height))
    }
  }

  #syncHiddenField() {
    if (this.hasHiddenFieldTarget) {
      this.hiddenFieldTarget.value = JSON.stringify(this.strokes)
    }
  }
}
