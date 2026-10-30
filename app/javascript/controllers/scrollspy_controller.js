import { Controller } from "@hotwired/stimulus"

// Marca en la navegación del portal la sección visible (aria-current).
export default class extends Controller {
  connect() {
    this.enlaces = [...this.element.querySelectorAll(".nav-portal a")]
    const porId = Object.fromEntries(
      this.enlaces.map(a => [a.getAttribute("href").slice(1), a])
    )
    this.observer = new IntersectionObserver(entries => {
      entries.forEach(e => {
        if (e.isIntersecting) {
          this.enlaces.forEach(a => a.removeAttribute("aria-current"))
          porId[e.target.id]?.setAttribute("aria-current", "true")
        }
      })
    }, { rootMargin: "-30% 0px -60% 0px" })
    this.element.querySelectorAll("main section[id]").forEach(s => this.observer.observe(s))
  }

  disconnect() {
    this.observer?.disconnect()
  }
}
