import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["redScore", "blueScore", "redWin", "blueWin"]

  connect() {
    this.updateResult()
  }

  updateResult() {
    if (!this.hasRedScoreTarget || !this.hasBlueScoreTarget) return

    const red = parseFloat(this.redScoreTarget.textContent) || 0
    const blue = parseFloat(this.blueScoreTarget.textContent) || 0

    if (this.hasRedWinTarget && this.hasBlueWinTarget) {
      if (red > blue) {
        this.redWinTarget.classList.remove("hidden")
        this.blueWinTarget.classList.add("hidden")
      } else if (blue > red) {
        this.blueWinTarget.classList.remove("hidden")
        this.redWinTarget.classList.add("hidden")
      } else {
        // Tie
        this.redWinTarget.classList.add("hidden")
        this.blueWinTarget.classList.add("hidden")
      }
    }
  }
}
