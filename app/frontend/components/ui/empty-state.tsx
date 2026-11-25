import type { ReactNode } from "react"
import { DotIllustration, type Figure } from "./dot-illustration"

// Estado vacío (Paper «12 · Estados vacíos»): centrado en el panel, ilustración de puntos, título, texto y acciones.
// Dice qué es la pantalla y el primer paso; un solo botón en tinta, y solo si es el primer paso del producto.
export function EmptyState({ figure, title, children, actions, command }: { figure: Figure; title: ReactNode; children?: ReactNode; actions?: ReactNode; command?: string }) {
  return (
    <div className="flex flex-col items-center gap-3 px-6 py-12 text-center">
      <DotIllustration figure={figure} />
      <h2 className="mt-5 text-lg font-medium text-foreground">{title}</h2>
      {children && <p className="max-w-[44ch] text-sm text-muted-foreground">{children}</p>}
      {actions && <div className="mt-3 flex flex-wrap items-center justify-center gap-3">{actions}</div>}
      {command && <code className="mt-3 font-mono text-control text-muted-foreground">{command}</code>}
    </div>
  )
}
