import type { ReactNode } from "react"
import { Eyebrow } from "./eyebrow"
import { Icon } from "./icons"

// Columna lateral (10): secciones con eyebrow. Cambios (fecha en mono), decisiones (sin «VIGENTE»),
// pantallas y actividad con robot para los agentes.
export function SideSection({ title, children }: { title: string; children: ReactNode }) {
  return (
    <section className="flex flex-col gap-3">
      <Eyebrow className="border-b border-border pb-2">{title}</Eyebrow>
      {children}
    </section>
  )
}

export function SideChange({ date, title, refs }: { date: string; title: string; refs?: string[] }) {
  return (
    <div className="flex gap-4">
      <span className="w-12 shrink-0 font-mono text-label text-muted-foreground">{date}</span>
      <div className="flex flex-col gap-1">
        <span className="text-sm text-foreground">{title}</span>
        {refs && <span className="font-mono text-label text-muted-foreground">{refs.join(" · ")}</span>}
      </div>
    </div>
  )
}

export function SideDecision({ reference, title }: { reference: string; title: string }) {
  return (
    <div className="flex flex-col gap-1">
      <span className="font-mono text-label text-foreground">{reference}</span>
      <span className="text-sm text-foreground">{title}</span>
    </div>
  )
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
