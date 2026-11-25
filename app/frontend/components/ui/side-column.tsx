import type { ReactNode } from "react"
import { Eyebrow } from "./eyebrow"
import { Icon } from "./icons"

// Columna lateral (10, «v1 · 3 · Capacidad»): secciones con eyebrow y filas con separador fino arriba.
// Cambios (fecha en mono), decisiones (sin «VIGENTE»), pantallas y actividad con robot para los agentes.
export function SideSection({ title, children, labelledBy }: { title: string; children: ReactNode; labelledBy?: string }) {
  return (
    <section aria-labelledby={labelledBy} className="flex flex-col gap-2.5">
      <h2 id={labelledBy} className="contents"><Eyebrow className="leading-[14px]">{title}</Eyebrow></h2>
      <div className="flex flex-col">{children}</div>
    </section>
  )
}

export function SideChange({ date, title, refs, href }: { date: string; title: string; refs?: string[]; href?: string }) {
  const body = (
    <>
      <span className="font-mono text-label leading-5 text-muted-foreground">{date}</span>
      <span className="flex flex-col gap-[3px]">
        <span className="text-sm leading-5 text-foreground">{title}</span>
        {refs && <span className="font-mono text-label leading-[14px] text-muted-foreground">{refs.join(" · ")}</span>}
      </span>
    </>
  )
  const className = "grid grid-cols-[52px_1fr] gap-3.5 border-t border-border py-3"
  return href ? <a href={href} className={className}>{body}</a> : <div className={className}>{body}</div>
}

export function SideDecision({ reference, title, href }: { reference: string; title: string; href?: string }) {
  const body = (
    <>
      <span className="font-mono text-label leading-[14px] text-foreground">{reference}</span>
      <span className="text-control leading-[19px] text-body">{title}</span>
    </>
  )
  const className = "flex flex-col gap-[3px] border-t border-border py-2.5"
  return href ? <a href={href} className={className}>{body}</a> : <div className={className}>{body}</div>
}

export function SideActivity({ actor, agent, text, when }: { actor: string; agent?: boolean; text: string; when: string }) {
  return (
    <div className="flex items-center gap-2 text-control text-muted-foreground">
      {agent && <Icon name="robot" size={13} />}
      <span className="font-mono text-label text-foreground">{actor}</span>
      <span>{text} · {when}</span>
    </div>
  )
}
