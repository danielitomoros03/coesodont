import { Controller } from "@hotwired/stimulus"

// Sparkline del promedio ponderado por período (PPS).
// points: [["2022-A", 14.2], ...] en orden cronológico, escala 0-20.
export default class extends Controller {
  static targets = ["svg", "tooltip"]
  static values = { points: Array }

  connect() {
    const PPS = this.pointsValue
    if (PPS.length < 2) return

    const svg = this.svgTarget
    const tip = this.tooltipTarget
    const W = 460, H = 150, m = { t: 16, r: 18, b: 26, l: 40 }
    const valores = PPS.map(d => d[1])
    const yMin = Math.max(0, Math.floor(Math.min(...valores)) - 1)
    const yMax = Math.min(20, Math.ceil(Math.max(...valores)) + 1)
    const iw = W - m.l - m.r, ih = H - m.t - m.b
    const x = i => m.l + (i / (PPS.length - 1)) * iw
    const y = v => m.t + (1 - (v - yMin) / (yMax - yMin)) * ih
    const fmt = v => v.toFixed(1).replace(".", ",")
    const NS = "http://www.w3.org/2000/svg"
    const el = (tag, attrs) => {
      const e = document.createElementNS(NS, tag)
      for (const k in attrs) e.setAttribute(k, attrs[k])
      svg.appendChild(e)
      return e
    }

    // retícula recesiva: dos cortes enteros, cifras al margen izquierdo
    const paso = Math.max(1, Math.round((yMax - yMin) / 3))
    for (let v = yMin + paso; v < yMax; v += paso) {
      el("line", { x1: m.l, x2: W - m.r, y1: y(v), y2: y(v), stroke: "rgba(38,27,65,.08)", "stroke-width": 1 })
      el("text", { x: m.l - 8, y: y(v) + 3, "text-anchor": "end", "font-size": 9.5, fill: "#A29CB5",
                   "font-family": "IBM Plex Mono, monospace" }).textContent = fmt(v)
    }

    // área: velo al 10 %
    const pts = PPS.map((d, i) => `${x(i)},${y(d[1])}`).join(" ")
    el("polygon", { points: `${m.l},${y(yMin)} ${pts} ${x(PPS.length - 1)},${y(yMin)}`,
                    fill: "rgba(51,0,102,.09)" })
    // línea: 2px, uniones redondas
    el("polyline", { points: pts, fill: "none", stroke: "#330066", "stroke-width": 2,
                     "stroke-linejoin": "round", "stroke-linecap": "round" })

    // etiquetas del eje x — extremos anclados hacia adentro para no recortarse
    PPS.forEach((d, i) => {
      const anchor = i === 0 ? "start" : (i === PPS.length - 1 ? "end" : "middle")
      el("text", { x: x(i), y: H - 8, "text-anchor": anchor, "font-size": 9,
                   fill: "#A29CB5", "font-family": "IBM Plex Mono, monospace" }).textContent = d[0]
    })

    // punto final con anillo de superficie + etiqueta directa
    const last = PPS.length - 1
    el("circle", { cx: x(last), cy: y(PPS[last][1]), r: 6, fill: "#FDFDFB" })
    el("circle", { cx: x(last), cy: y(PPS[last][1]), r: 4, fill: "#330066" })
    el("text", { x: x(last), y: y(PPS[last][1]) - 12, "text-anchor": "middle", "font-size": 11.5,
                 "font-weight": 700, fill: "#261B41", "font-family": "Archivo, sans-serif" })
      .textContent = fmt(PPS[last][1])

    // capa de hover: objetivo más grande que la marca
    const dot = el("circle", { r: 4.5, fill: "#330066", stroke: "#FDFDFB", "stroke-width": 2, opacity: 0 })
    PPS.forEach((d, i) => {
      const hit = el("rect", {
        x: x(i) - iw / (PPS.length - 1) / 2, y: 0, width: iw / (PPS.length - 1), height: H,
        fill: "transparent", cursor: "pointer"
      })
      const show = () => {
        dot.setAttribute("cx", x(i)); dot.setAttribute("cy", y(d[1]))
        dot.setAttribute("opacity", 1)
        tip.innerHTML = `${d[0]}<b>${fmt(d[1])} / 20</b>`
        const box = svg.getBoundingClientRect()
        tip.style.left = (x(i) / W * box.width) + "px"
        tip.style.top = (y(d[1]) / H * box.height) + "px"
        tip.style.opacity = 1
      }
      const hide = () => { dot.setAttribute("opacity", 0); tip.style.opacity = 0 }
      hit.addEventListener("mouseenter", show)
      hit.addEventListener("mouseleave", hide)
      hit.addEventListener("focus", show)
      hit.addEventListener("blur", hide)
    })
  }
}
