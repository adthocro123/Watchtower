import { Controller } from "@hotwired/stimulus"

// Switchable line chart that swaps datasets based on a select dropdown.
// Pre-receives all stat series as JSON; rebuilds the chart on stat change.
//
// Usage:
//   data-controller="stat-chart"
//   data-stat-chart-all-data-value='{"total_points":[{name:"#254",data:{...}},...], ...}'
//   data-stat-chart-colors-value='["#f97316","#3b82f6",...]'

const CHART_COLORS = ["#f97316", "#3b82f6", "#f59e0b", "#ef4444", "#8b5cf6", "#ec4899"]

export default class extends Controller {
  static targets = ["canvas", "select"]

  static values = {
    allData: { type: Object, default: {} },
    colors: { type: Array, default: CHART_COLORS }
  }

  connect() {
    this.chart = null
    this.#waitForChartJS()
  }

  disconnect() {
    if (this.chart) {
      this.chart.destroy()
      this.chart = null
    }
  }

  changeStat() {
    this.#render()
  }

  #waitForChartJS(attempts = 0) {
    if (typeof Chart !== "undefined") {
      this.#render()
    } else if (attempts < 20) {
      setTimeout(() => this.#waitForChartJS(attempts + 1), 100)
    }
  }

  #render() {
    const stat = this.selectTarget.value
    const seriesArray = this.allDataValue[stat]
    if (!seriesArray) return

    const canvas = this.canvasTarget
    if (!canvas) return

    // Collect all unique labels in order
    const allLabels = []
    seriesArray.forEach(series => {
      Object.keys(series.data).forEach(label => {
        if (!allLabels.includes(label)) allLabels.push(label)
      })
    })

    allLabels.sort((a, b) => {
      const aKey = this.#matchLabelSortKey(a)
      const bKey = this.#matchLabelSortKey(b)

      for (let i = 0; i < Math.max(aKey.length, bKey.length); i += 1) {
        const aPart = aKey[i] ?? 0
        const bPart = bKey[i] ?? 0
        if (aPart !== bPart) return aPart - bPart
      }

      return a.localeCompare(b)
    })

    const datasets = seriesArray.map((series, i) => ({
      label: series.name,
      data: allLabels.map(label => series.data[label] ?? null),
      borderColor: this.colorsValue[i % this.colorsValue.length],
      backgroundColor: this.colorsValue[i % this.colorsValue.length],
      borderWidth: 2,
      pointRadius: 3,
      pointHoverRadius: 5,
      tension: 0.1,
      spanGaps: true
    }))

    if (this.chart) {
      this.chart.data.labels = allLabels
      this.chart.data.datasets = datasets
      this.chart.update()
    } else {
      this.chart = new Chart(canvas, {
        type: "line",
        data: { labels: allLabels, datasets },
        options: {
          responsive: true,
          maintainAspectRatio: true,
          scales: {
            x: {
              ticks: { color: "#9ca3af" },
              grid: { color: "#1f2937" }
            },
            y: {
              ticks: { color: "#9ca3af" },
              grid: { color: "#1f2937" },
              beginAtZero: true
            }
          },
          plugins: {
            legend: {
              labels: { color: "#d1d5db" }
            }
          }
        }
      })
    }
  }

  #matchLabelSortKey(label) {
    const normalized = String(label || "").trim().toUpperCase()
    const qualificationMatch = normalized.match(/^Q(\d+)$/)
    if (qualificationMatch) {
      return [0, Number(qualificationMatch[1])]
    }

    const playoffMatch = normalized.match(/^(EF|QF|SF)(\d+)-(\d+)$/)
    if (playoffMatch) {
      const levelOrder = { EF: 1, QF: 2, SF: 3 }
      return [levelOrder[playoffMatch[1]], Number(playoffMatch[2]), Number(playoffMatch[3])]
    }

    const finalMatch = normalized.match(/^F(\d+)$/)
    if (finalMatch) {
      return [4, Number(finalMatch[1])]
    }

    return [99]
  }
}
