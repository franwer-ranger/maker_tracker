import type { ReactNode } from "react"
import { cx } from "./cx"

// Etiqueta en mayúsculas (Geist Mono 11px, tracking 0.08em): eyebrows y nombres de sección.
export function Eyebrow({ children, className }: { children: ReactNode; className?: string }) {
  return <span className={cx("font-mono text-label tracking-label text-muted-foreground uppercase", className)}>{children}</span>
}
