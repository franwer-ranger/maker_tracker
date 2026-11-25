import { usePage } from "@inertiajs/react"
import { createContext, type ReactNode, useContext, useEffect, useMemo, useState } from "react"
import type { PresenceEditing } from "@/types"
import { cx } from "./cx"
import { Icon } from "./icons"

// Presencia en directo (MT-100, Paper «v1 · 1 · Sistema» › «09 · Presencia del agente»). Quien escribe por la API
// o la CLI deja su recurso «en edición» unos segundos: el panel lleva el marco naranja y la pestaña, y el elemento
// que se toca (marcado con `data-presence`) su contorno y la etiqueta. Es el único naranja que se mueve.

type Editing = PresenceEditing & { until: number }

const PresenceContext = createContext<Editing[]>([])

// Lo que se está editando ahora. Cada entrada trae cuántos ms le quedan: se apaga sola al pasar, aunque la emisión
// del final no llegue (varias pestañas, un corte), para que la presencia caducada no se quede pintada.
export function PresenceProvider({ children }: { children: ReactNode }) {
  const { props: { presence } } = usePage()
  const [now, setNow] = useState(() => Date.now())
  const received = useMemo(() => {
    const at = Date.now()
    return (presence?.editing ?? []).map((entry) => ({ ...entry, until: at + entry.left_ms }))
  }, [presence])

  const live = received.filter((entry) => entry.until > now)
  const next = Math.min(...live.map((entry) => entry.until))

  useEffect(() => {
    if (!Number.isFinite(next)) return
    const timer = window.setTimeout(() => setNow(Date.now()), Math.max(next - Date.now(), 0) + 20)
    return () => window.clearTimeout(timer)
  }, [next])

  return <PresenceContext.Provider value={live}>{children}</PresenceContext.Provider>
}

export const usePresenceEditing = () => useContext(PresenceContext)

// La matriz de puntos que se encienden y apagan al azar: un fotograma nuevo cada 120–160 ms, generado en cada
// ciclo para que no se vea patrón. Con «reducir movimiento», fija.
export function DotMatrix({ cols, rows, dot, tone }: { cols: number; rows: number; dot: number; tone: "signal" | "inverse" }) {
  const [frame, setFrame] = useState(() => randomFrame(cols * rows, 7))

  useEffect(() => {
    if (window.matchMedia?.("(prefers-reduced-motion: reduce)").matches) return
    let timer = 0
    let seed = 0
    const tick = () => {
      seed += 1
      setFrame(randomFrame(cols * rows, seed))
      timer = window.setTimeout(tick, 120 + Math.random() * 40)
    }
    timer = window.setTimeout(tick, 140)
    return () => window.clearTimeout(timer)
  }, [cols, rows])

  return (
    <span aria-hidden="true" data-presence-matrix className="grid shrink-0 gap-[2px]" style={{ gridTemplateColumns: `repeat(${cols}, ${dot}px)` }}>
      {frame.map((on, index) => (
        <span
          // biome-ignore lint/suspicious/noArrayIndexKey: los puntos son posiciones fijas de la matriz
          key={index}
          className={cx("rounded-full", tone === "signal" ? (on ? "bg-signal" : "bg-signal/20") : on ? "bg-white" : "bg-white/30")}
          style={{ width: dot, height: dot }}
        />
      ))}
    </span>
  )
}

// Al azar, pero nunca vacío ni lleno del todo. `seed` solo distingue el fotograma fijo (reducir movimiento).
function randomFrame(size: number, seed: number) {
  const frame = Array.from({ length: size }, (_, index) => (seed === 7 ? (index * 7 + 3) % 5 < 3 : Math.random() < 0.55))
  if (frame.every(Boolean)) frame[0] = false
  if (!frame.some(Boolean)) frame[0] = true
  return frame
}

// Quién: robot para agentes, inicial en un círculo para personas.
export function PresenceWho({ agent, name, size = 13, tone = "signal" }: { agent: boolean; name: string; size?: number; tone?: "signal" | "inverse" }) {
  if (agent) return <Icon name="robot" size={size} strokeWidth={1.8} className={tone === "signal" ? "text-signal" : "text-white"} />
  return (
    <span
      aria-hidden="true"
      className={cx(
        "flex shrink-0 items-center justify-center rounded-full font-mono text-[9px] leading-none uppercase",
        tone === "signal" ? "bg-signal text-white" : "bg-white text-signal",
      )}
      style={{ width: size, height: size }}
    >
      {name[0]}
    </span>
  )
}

// La pestaña arriba del panel: matriz + quién + «claude está editando Revelarlo». Lleva a lo que se toca.
export function PresenceTab({ entries }: { entries: Editing[] }) {
  const [first] = entries
  if (!first) return null
  const others = entries.length - 1
  const text = `${first.actor} está editando ${first.label}${others > 0 ? ` y ${others} más` : ""}`
  const go = () => {
    const element = first.key ? document.querySelector(`[data-presence="${CSS.escape(first.key)}"]`) : null
    if (element) element.scrollIntoView({ behavior: "smooth", block: "center" })
    else if (first.url) window.location.assign(first.url)
  }
  return (
    <div className="pointer-events-none sticky top-0 z-20 flex h-0 justify-center">
      <button
        type="button"
        role="status"
        onClick={go}
        className="pointer-events-auto flex h-fit max-w-[calc(100%-2rem)] items-center gap-2 rounded-b-lg bg-signal pt-1 pr-3 pb-[5px] pl-2.5 font-mono text-label text-white"
      >
        <DotMatrix cols={6} rows={3} dot={3} tone="inverse" />
        <PresenceWho agent={first.agent} name={first.actor} tone="inverse" />
        <span className="truncate">{text}</span>
      </button>
    </div>
  )
}

// El elemento que se puede estar tocando (capacidad, historia, decisión, sección, hito): `target` es su clave
// («story:12», «page:revelarlo», «decision:5», «milestone:2», «brief»). Mientras se edita, contorno naranja y la
// etiqueta con la matriz y quién (sin nombre: el nombre va en la barra lateral y la pestaña).
export function PresenceOutline({ target, as: Tag = "div", className, children }: { target: string; as?: "div" | "article" | "section"; className?: string; children: ReactNode }) {
  const entry = usePresenceEditing().find((it) => it.key === target)
  return (
    <Tag data-presence={target} className={cx("relative rounded-lg", entry && "outline-[1.5px] outline-offset-4 outline-signal outline-solid", className)}>
      {entry && (
        <span
          title={`${entry.actor} está editando`}
          className="absolute -top-3.5 right-2 z-10 flex items-center gap-[5px] rounded-md bg-background px-1.5 py-[3px] shadow-[0_0_0_1.5px_var(--signal)]"
        >
          <DotMatrix cols={5} rows={3} dot={2} tone="signal" />
          <PresenceWho agent={entry.agent} name={entry.actor} size={12} />
          <span className="sr-only">{entry.actor} está editando</span>
        </span>
      )}
      {children}
    </Tag>
  )
}
