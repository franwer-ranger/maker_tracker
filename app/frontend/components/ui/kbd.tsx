import type { ReactNode } from "react"
import { cx } from "./cx"

// Atajo visible (receta: «teclado como Raycast»).
export function Kbd({ children, className }: { children: ReactNode; className?: string }) {
  return (
    <kbd className={cx("inline-flex h-5 min-w-5 items-center justify-center rounded-sm bg-kbd px-1 font-mono text-label text-muted-foreground", className)}>
      {children}
    </kbd>
  )
}
