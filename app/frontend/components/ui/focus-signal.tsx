import type { ReactNode } from "react"
import { cx } from "./cx"

// Señal de enfoque: el punto naranja para lo que pide atención (te toca, bloquea, lo urgente).
// `soft` lo pone en un aviso con fondo --signal-soft y borde completo.
export function FocusSignal({ children, soft = false, className }: { children: ReactNode; soft?: boolean; className?: string }) {
  return (
    <span
      className={cx(
        "inline-flex items-center gap-2 text-control text-signal",
        soft && "rounded-md border border-signal/25 bg-signal-soft px-2.5 py-1 text-foreground",
        className,
      )}
    >
      <span aria-hidden="true" className="size-1.5 shrink-0 rounded-full bg-signal" />
      {children}
    </span>
  )
}
