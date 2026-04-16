import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "icon"]

  toggle(event) {
    event.preventDefault()
    const isHidden = this.inputTarget.type === "password"
    this.inputTarget.type = isHidden ? "text" : "password"
    if (this.hasIconTarget) {
      this.iconTarget.classList.toggle("fa-eye", !isHidden)
      this.iconTarget.classList.toggle("fa-eye-slash", isHidden)
    }
  }
}
