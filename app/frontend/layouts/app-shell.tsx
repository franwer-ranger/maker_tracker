import { Head, Link, usePage } from "@inertiajs/react"
import type { ReactNode } from "react"
import { CommandPalette } from "@/components/ui/command-palette"
import { cx } from "@/components/ui/cx"

// El marco de la v1 (MT-87 · Estructura): barra lateral oscura y el contenido en un panel claro dentro del marco.
// Solo la portada es de Inertia; Tablero, Roadmap y Brief siguen siendo las vistas de Hotwire.
export function AppShell({ title, active, children }: { title: string; active?: "cover"; children: ReactNode }) {
  const { project, nav, notice } = usePage().props
  const links = [
    { key: "cover", label: "Portada", href: nav.cover, inertia: true },
    { key: "board", label: "Tablero", href: nav.board },
    { key: "roadmap", label: "Roadmap", href: nav.roadmap },
    { key: "brief", label: "Brief y decisiones", href: nav.brief },
  ]

  return (
    <div className="flex min-h-svh flex-col md:h-svh md:flex-row">
      <Head title={title} />
      <aside className="flex shrink-0 flex-col gap-6 px-3 py-4 text-sidebar-foreground md:w-60">
        <div className="flex items-center gap-2.5 px-1.5">
          <span className="flex size-7 items-center justify-center rounded-md bg-sidebar-active font-mono text-label text-sidebar-foreground">{project.key}</span>
          <span className="truncate text-sm font-semibold text-white">{project.name}</span>
        </div>
        <CommandPalette />
        <nav aria-label="Proyecto" className="flex flex-row gap-0.5 overflow-x-auto md:flex-col">
          {links.map((link) => {
            const className = cx(
              "flex h-8 shrink-0 items-center rounded-md px-2.5 text-control transition-colors",
              active === link.key ? "bg-sidebar-active text-white" : "text-sidebar-muted hover:text-sidebar-foreground",
            )
            return link.inertia ? (
              <Link key={link.key} href={link.href} className={className} aria-current={active === link.key ? "page" : undefined}>{link.label}</Link>
            ) : (
              <a key={link.key} href={link.href} className={className}>{link.label}</a>
            )
          })}
        </nav>
        <p className="mt-auto hidden px-1.5 font-mono text-label text-sidebar-muted md:block">v1 · prueba del stack (MT-99)</p>
      </aside>
      <main className="min-w-0 flex-1 p-0 md:py-2 md:pr-2">
        <div className="h-full overflow-y-auto bg-background md:rounded-frame">
          {notice && (
            <p role="status" className="border-b border-border bg-card px-6 py-2 text-control text-foreground">{notice}</p>
          )}
          {children}
        </div>
      </main>
    </div>
  )
}
