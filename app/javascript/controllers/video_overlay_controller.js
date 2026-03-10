import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    step: { type: String, default: "full_match" }
  }
}
