import type { ReactNode } from "react"
import { Eyebrow } from "./eyebrow"
import { Icon, type IconName } from "./icons"

// Cabecera de página (10): icono en casilla gris, eyebrow en mono, estado; título en Instrument Serif; entradilla.
export function PageHeader({ icon, eyebrow, status, title, lead }: { icon?: IconName; eyebrow?: ReactNode; status?: ReactNode; title: ReactNode; lead?: ReactNode }) {
  return (
    <header className="flex flex-col gap-4">
      {(icon || eyebrow || status) && (
        <div className="flex items-center gap-3">
          {icon && (
            <span className="inline-flex size-8 items-center justify-center rounded-md bg-muted text-foreground">
              <Icon name={icon} size={15} />
            </span>
          )}
          {eyebrow && <Eyebrow>{eyebrow}</Eyebrow>}
          {status}
        </div>
      )}
      <h1 className="font-display text-[48px] leading-[1.05] font-normal tracking-[-0.01em] text-foreground text-balance">{title}</h1>
      {lead && <p className="max-w-[60ch] text-lg text-body">{lead}</p>}
    </header>
  )
}
