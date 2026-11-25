import type { ReactNode } from "react"
import { cx } from "./cx"

// Atajo visible (08 · Mono): borde fino, Geist Mono 10px en --kbd. `tone="sidebar"` dentro del marco oscuro.
export function Kbd({ children, className, tone = "panel" }: { children: ReactNode; className?: string; tone?: "panel" | "sidebar" | "ink" }) {
  return (
    <kbd
      className={cx(
        "inline-flex h-4 min-w-4 items-center justify-center rounded-sm border px-1 font-mono text-[10px] leading-[14px] text-kbd",
        tone === "panel" && "border-border",
        tone === "sidebar" && "border-sidebar-kbd",
        tone === "ink" && "border-primary-foreground/25 text-primary-foreground/60",
        className,
      )}
    >
      {children}
    </kbd>
  )
}
