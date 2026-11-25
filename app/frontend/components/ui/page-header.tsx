import type { ReactNode } from "react"
import { Eyebrow } from "./eyebrow"
import { Icon, type IconName } from "./icons"

// Cabecera de página (10, «v1 · 3 · Capacidad»): icono en casilla gris, eyebrow en mono, estado; título en Instrument Serif; entradilla.
export function PageHeader({ icon, eyebrow, status, title, lead }: { icon?: IconName; eyebrow?: ReactNode; status?: ReactNode; title: ReactNode; lead?: ReactNode }) {
  return (
    <header className="flex flex-col gap-4">
      {(icon || eyebrow || status) && (
        <div className="flex flex-wrap items-center gap-3">
          {icon && (
            <span className="inline-flex size-8 items-center justify-center rounded-lg bg-muted text-foreground">
              <Icon name={icon} size={16} />
            </span>
          )}
          {eyebrow && <Eyebrow className="leading-[14px] tracking-[0.1em]">{eyebrow}</Eyebrow>}
          {status}
        </div>
      )}
      <h1 className="font-display text-[38px] leading-[42px] font-normal text-foreground text-balance md:text-[46px] md:leading-[50px]">{title}</h1>
      {lead && <p className="text-base leading-[25px] text-body md:text-[17px] md:leading-[27px]">{lead}</p>}
    </header>
  )
}
