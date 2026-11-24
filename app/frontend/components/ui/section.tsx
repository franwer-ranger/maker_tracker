import type { ReactNode } from "react"

// Sección numerada 01–05 en mono (receta de MT-87).
export function Section({ index, title, aside, children, id }: { index: string; title: string; aside?: ReactNode; children: ReactNode; id?: string }) {
  const headingId = `${id ?? `seccion-${index}`}-titulo`
  return (
    <section id={id} aria-labelledby={headingId} className="flex flex-col gap-4">
      <div className="flex items-baseline justify-between gap-4 border-b border-border pb-2">
        <h2 id={headingId} className="flex items-baseline gap-3 font-mono text-label uppercase tracking-label text-muted-foreground">
          <span className="text-foreground">{index}</span>
          {title}
        </h2>
        {aside}
      </div>
      {children}
    </section>
  )
}
