import { Head, Link, usePage } from "@inertiajs/react"
import { type ReactNode, useEffect, useState } from "react"
import { AgentWorking } from "@/components/ui/agent-working"
import { CommandPalette } from "@/components/ui/command-palette"
import { CopyForAgent } from "@/components/ui/copy-for-agent"
import { cx } from "@/components/ui/cx"
import { Icon, type IconName, Logo } from "@/components/ui/icons"
import { Kbd } from "@/components/ui/kbd"
import { ProductCombo } from "@/components/ui/product-combo"
import { ThemeToggle } from "@/components/ui/theme-toggle"
import { TopBar } from "@/components/ui/top-bar"

type Section = "product" | "stories" | "roadmap" | "decisions"

// El marco (MT-101, Paper «v1 · 11 · ⌘K» y portadas): barra lateral oscura con logo, Taller, combo de producto,
// navegación, mapa de capacidades, agente trabajando, usuario y ⌘K; el panel claro con esquinas redondeadas
// y su barra superior. En móvil, cabecera oscura con producto, copiar y menú.
export function AppShell({ title, active, crumbs, actions, children }: { title: string; active?: Section; crumbs?: { label: string; href?: string }[]; actions?: ReactNode; children: ReactNode }) {
  const { project, nav, notice, frame } = usePage().props
  const [paletteOpen, setPaletteOpen] = useState(false)
  const [menuOpen, setMenuOpen] = useState(false)

  useEffect(() => {
    const onKey = (event: KeyboardEvent) => {
      if ((event.metaKey || event.ctrlKey) && event.key.toLowerCase() === "k") {
        event.preventDefault()
        setPaletteOpen((open) => !open)
      }
    }
    window.addEventListener("keydown", onKey)
    return () => window.removeEventListener("keydown", onKey)
  }, [])

  const links: { key: Section; label: string; icon: IconName; href: string; inertia?: boolean }[] = [
    { key: "product", label: "Producto", icon: "product", href: nav.cover, inertia: true },
    { key: "stories", label: "Historias", icon: "stories", href: nav.board },
    { key: "roadmap", label: "Roadmap", icon: "roadmap", href: nav.roadmap },
    { key: "decisions", label: "Decisiones", icon: "decision", href: nav.brief },
  ]
  const copyText = `mt context --project ${project.key}`

  const sidebar = (
    <>
      <div className="flex items-center gap-2.5 px-1.5">
        <Logo />
        <span className="text-[15px] leading-[18px] font-medium text-sidebar-foreground">Maker Tracker</span>
      </div>
      <a href={nav.board} className="flex items-center justify-between rounded-[7px] px-2.5 py-1.5 text-sm text-sidebar-muted hover:text-sidebar-foreground">
        <span className="flex items-center gap-2.5"><Icon name="taller" />Taller</span>
        <span className="font-mono text-label">{frame.taller}</span>
      </a>
      <ProductCombo products={frame.products} current={project.key} />
      <nav aria-label="Producto" className="flex flex-col gap-px">
        {links.map((link) => {
          const current = active === link.key
          const className = cx(
            "flex items-center gap-2.5 rounded-[7px] px-2.5 py-1.5 text-sm transition-colors",
            current ? "bg-sidebar-accent text-sidebar-active" : "text-sidebar-muted hover:text-sidebar-foreground",
          )
          const content = <><Icon name={link.icon} />{link.label}</>
          return link.inertia ? (
            <Link key={link.key} href={link.href} className={className} aria-current={current ? "page" : undefined}>{content}</Link>
          ) : (
            <a key={link.key} href={link.href} className={className}>{content}</a>
          )
        })}
      </nav>
      {frame.capabilities.length > 0 && (
        <nav aria-label="Capacidades" className="flex min-h-0 flex-col gap-4 overflow-y-auto">
          {frame.capabilities.map(({ area, items }) => (
            <div key={area ?? "-"} className="flex flex-col">
              {area && <span className="px-2.5 pb-1 font-mono text-[10px] leading-3 tracking-[0.12em] text-[#4E5058] uppercase">{area}</span>}
              {items.map((item) => (
                <Link key={item.slug} href={item.url} className="rounded-md px-2.5 py-[3px] text-control text-sidebar-muted hover:text-sidebar-foreground">{item.title}</Link>
              ))}
            </div>
          ))}
        </nav>
      )}
      <div className="mt-auto flex flex-col gap-3 px-2.5">
        {frame.agents.map((agent) => <AgentWorking key={agent.name} agent={agent.name} target={agent.target} />)}
        <div className="flex items-center justify-between gap-2">
          {frame.user && (
            <span className="flex items-center gap-2 text-control text-sidebar-muted">
              <span className="flex size-[22px] items-center justify-center rounded-full bg-[#2B2C31] text-label text-sidebar-foreground uppercase">{frame.user[0]}</span>
              {frame.user}
            </span>
          )}
          <span className="flex items-center gap-1">
            <ThemeToggle />
            <button type="button" onClick={() => setPaletteOpen(true)} aria-label="Abrir ⌘K" className="rounded-sm">
              <Kbd tone="sidebar">⌘K</Kbd>
            </button>
          </span>
        </div>
      </div>
    </>
  )

  return (
    <div className="flex min-h-svh flex-col bg-sidebar md:h-svh md:flex-row">
      <Head title={title} />
      {/* Móvil: cabecera oscura con producto, buscar, copiar y menú. */}
      <header className="sticky top-0 z-30 flex h-14 items-center justify-between gap-3 bg-sidebar px-4 md:hidden">
        <div className="min-w-0 flex-1"><ProductCombo products={frame.products} current={project.key} /></div>
        <button type="button" aria-label="Buscar" onClick={() => setPaletteOpen(true)} className="p-1.5 text-sidebar-foreground"><Icon name="search" size={17} /></button>
        <CopyForAgent text={copyText} label="" shortcut={null} className="px-1.5 text-sidebar-foreground hover:text-sidebar-active [&>span]:hidden" />
        <button type="button" aria-label="Menú" aria-expanded={menuOpen} onClick={() => setMenuOpen((open) => !open)} className="p-1.5 text-sidebar-foreground"><Icon name="menu" size={18} /></button>
      </header>
      <aside className={cx("shrink-0 flex-col gap-[18px] pt-5 pr-3 pb-[18px] pl-4 md:flex md:w-60", menuOpen ? "flex" : "hidden")}>{sidebar}</aside>
      <main className="min-w-0 flex-1 md:py-2.5 md:pr-2.5">
        <div className="flex h-full flex-col overflow-y-auto rounded-t-[var(--radius-panel)] bg-background md:rounded-[var(--radius-panel)]">
          {crumbs && <TopBar crumbs={crumbs} actions={actions ?? <CopyForAgent text={copyText} />} />}
          {notice && <p role="status" className="border-b border-border bg-card px-7 py-2 text-control text-foreground">{notice}</p>}
          {children}
        </div>
      </main>
      <CommandPalette open={paletteOpen} onOpenChange={setPaletteOpen} />
    </div>
  )
}
