const relative = new Intl.RelativeTimeFormat("es", { numeric: "auto", style: "short" })

// «hace 3 min», «ayer»…
export function ago(iso: string, now = Date.now()) {
  const seconds = Math.round((new Date(iso).getTime() - now) / 1000)
  const steps: [Intl.RelativeTimeFormatUnit, number][] = [["second", 60], ["minute", 60], ["hour", 24], ["day", 7], ["week", 4.35], ["month", 12]]
  let value = seconds
  for (const [unit, size] of steps) {
    if (Math.abs(value) < size) return relative.format(unit === "second" ? Math.min(value, 0) : Math.round(value), unit)
    value /= size
  }
  return relative.format(Math.round(value), "year")
}
