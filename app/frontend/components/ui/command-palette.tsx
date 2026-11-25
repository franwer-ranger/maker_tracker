import { router, usePage } from "@inertiajs/react"
import {
  Command,
  CommandEmpty,
  CommandGroup,
  CommandGroupLabel,
  CommandInput,
  CommandItem,
  CommandItemText,
  CommandList,
  CommandStatus,
} from "@ui-sdk/react/command"
import { Dialog, DialogBackdrop, DialogContent, DialogDescription, DialogTitle } from "@ui-sdk/react/dialog"
import { type ReactNode, useEffect, useState } from "react"
import { setTheme, useTheme } from "@/lib/theme"
import type { SearchItem } from "@/types"
import { cx } from "./cx"
import { Icon, type IconName } from "./icons"
import { Kbd } from "./kbd"
import { ProductMark } from "./product-combo"
import { StateDot } from "./state-dot"

type Action = { value: string; label: string; icon: IconName; command?: string; shortcut?: string; hint?: string; run: () => void }

// ⌘K (MT-101, Paper «v1 · 11 · ⌘K»): ámbito el producto actual. «Ir a» (pantallas, capacidades, historias,
// decisiones) y «Acciones» con su atajo y su comando `mt`. ⇥ busca lo mismo en otro producto.
// Comportamiento de UI SDK (diálogo modal, combobox); el índice llega con una recarga parcial al abrir.
export function CommandPalette({ open, onOpenChange }: { open: boolean; onOpenChange: (open: boolean) => void }) {
  const { search, nav, project, frame } = usePage().props
  const [loading, setLoading] = useState(false)
  const [query, setQuery] = useState("")
  const [otherProduct, setOtherProduct] = useState(false)
  const theme = useTheme()
  const dark = theme.endsWith(":dark")

  useEffect(() => {
    if (!open) return
    setOtherProduct(false)
    router.reload({ only: ["search"], onStart: () => setLoading(true), onFinish: () => setLoading(false) })
  }, [open])

  const copy = (text: string) => {
    void navigator.clipboard?.writeText(text).catch(() => {})
  }

  const close = () => onOpenChange(false)
  const screens: SearchItem[] = [
    { value: "screen:product", ref: "", title: "Producto", meta: "Pantalla", url: nav.cover },
    { value: "screen:stories", ref: "", title: "Historias", meta: "Pantalla", url: nav.board },
    { value: "screen:roadmap", ref: "", title: "Roadmap", meta: "Pantalla", url: nav.roadmap },
    { value: "screen:decisions", ref: "", title: "Decisiones", meta: "Pantalla", url: nav.brief },
  ]
  const goTo: { item: SearchItem; icon: IconName }[] = [
    ...screens.map((item) => ({ item, icon: "arrowRight" as IconName })),
    ...(search?.capabilities ?? []).map((item) => ({ item, icon: "file" as IconName })),
    ...(search?.stories ?? []).map((item) => ({ item, icon: "stories" as IconName })),
    ...(search?.decisions ?? []).map((item) => ({ item, icon: "decision" as IconName })),
  ]
  // Las acciones sin pantalla propia todavía copian su comando `mt` para tu agente.
  const actions: Action[] = [
    { value: "action:idea", label: "Apuntar una idea", icon: "spark", command: "mt create", shortcut: "N", run: () => copy(`mt create "…" --project ${project.key}`) },
    { value: "action:story", label: "Nueva historia", icon: "pencil", command: "mt create --state defining", run: () => copy(`mt create "…" --state defining --project ${project.key}`) },
    { value: "action:decision", label: "Nueva decisión", icon: "decision", command: "mt decide", run: () => copy(`mt decide "…" --why "…" --project ${project.key}`) },
    { value: "action:product", label: "Cambiar de producto", icon: "swap", shortcut: "P", run: () => setOtherProduct(true) },
    { value: "action:copy", label: "Copiar para tu agente", icon: "copy", shortcut: "⌘⇧C", run: () => copy(`mt context --project ${project.key}`) },
    { value: "action:theme", label: "Tema claro / oscuro", icon: "contrast", hint: `Ahora: ${dark ? "oscuro" : "claro"}`, run: () => setTheme(dark ? "light" : "dark") },
  ]

  const run = (value: string) => {
    if (otherProduct) {
      const product = frame.products.find((item) => item.key === value)
      close()
      if (product) router.visit(product.url)
      return
    }
    const action = actions.find((item) => item.value === value)
    if (action) {
      action.run()
      if (action.value !== "action:product") close()
      return
    }
    const target = goTo.find(({ item }) => item.value === value)?.item
    if (!target) return
    close()
    // Lo que aún no es de Inertia (historia, tablero, brief) va con una carga completa.
    if (target.url.startsWith(nav.cover)) router.visit(target.url)
    else window.location.assign(target.url)
  }

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogBackdrop className="fixed inset-0 z-40 bg-[#0F0F11]/30 transition-opacity data-starting-style:opacity-0 data-ending-style:opacity-0" />
      <DialogContent className="fixed inset-0 z-50 flex flex-col overflow-hidden bg-card text-foreground transition data-starting-style:opacity-0 data-ending-style:opacity-0 md:inset-auto md:top-[13vh] md:left-1/2 md:max-h-[70vh] md:w-[min(680px,calc(100vw-32px))] md:-translate-x-1/2 md:rounded-xl md:border md:border-border md:shadow-[0_16px_40px_rgba(15,15,17,0.18)] md:data-starting-style:scale-[0.98]">
        <DialogTitle className="sr-only">Buscar en {project.name}</DialogTitle>
        <DialogDescription className="sr-only">Capacidades, historias, decisiones y acciones. Flechas para moverte, Enter para abrir, Tab para buscar en otro producto, Escape para cerrar.</DialogDescription>
        <Command
          onAction={run}
          status={loading && !search ? "loading" : "idle"}
          className="flex min-h-0 flex-1 flex-col"
          onKeyDown={(event) => {
            if (event.key === "Tab" && !event.shiftKey && frame.products.length > 1) {
              event.preventDefault()
              setOtherProduct((value) => !value)
            }
          }}
        >
          <div className="flex h-14 shrink-0 items-center gap-3 border-b border-border px-4">
            <Icon name="search" size={15} className="text-muted-foreground" />
            <CommandInput
              aria-label={otherProduct ? "Elegir otro producto" : `Buscar en ${project.name}`}
              placeholder={otherProduct ? "Elige el producto…" : "Busca una capacidad, historia o decisión…"}
              onChange={(event) => setQuery(event.currentTarget.value)}
              className="h-full min-w-0 flex-1 bg-transparent text-base outline-none placeholder:text-muted-foreground focus-visible:shadow-none"
            />
            <CommandStatus className="hidden font-mono text-label text-muted-foreground sm:block">{(state) => (state.loading ? "cargando" : `${state.count} resultados`)}</CommandStatus>
            <span className="flex items-center gap-2 rounded-md border border-border px-2 py-1 text-control">
              <ProductMark code={project.key} size={16} />
              {project.name}
            </span>
            <button type="button" onClick={close} className="text-control text-muted-foreground md:hidden">Cerrar</button>
          </div>
          <CommandEmpty className="px-4 py-8 text-center text-sm text-muted-foreground not-data-empty:not-data-loading:hidden">
            {(state) => (state.loading ? "Cargando…" : state.empty ? `Nada coincide con «${state.query}» en ${project.name}.` : null)}
          </CommandEmpty>
          <CommandList className="min-h-0 flex-1 overflow-y-auto p-1.5">
            {otherProduct ? (
              <Group label="Otro producto">
                {frame.products.filter((product) => product.key !== project.key).map((product) => (
                  <Row key={product.key} value={product.key} label={`${product.name} ${product.key}`} lead={<ProductMark code={product.key} size={16} />} title={product.name} />
                ))}
              </Group>
            ) : (
              <>
                <Group label="Ir a">
                  {goTo.map(({ item, icon }) => (
                    <Row
                      key={item.value}
                      value={item.value}
                      label={`${item.ref} ${item.title}`}
                      keywords={[item.meta]}
                      lead={<Icon name={icon} size={14} className="text-muted-foreground" />}
                      code={item.ref || undefined}
                      title={item.title}
                      trail={
                        <span className="flex items-center gap-1.5 text-control text-muted-foreground">
                          {item.state && <StateDot state={item.state} />}
                          {item.meta}
                        </span>
                      }
                    />
                  ))}
                </Group>
                <Group label="Acciones">
                  {actions.map((action) => (
                    <Row
                      key={action.value}
                      value={action.value}
                      label={action.label}
                      keywords={action.command ? [action.command] : []}
                      lead={<Icon name={action.icon} size={14} className="text-muted-foreground" />}
                      title={action.label}
                      trail={
                        <span className="flex items-center gap-3 text-control text-muted-foreground">
                          {action.command && <span className="font-mono text-label">{action.command}</span>}
                          {action.hint}
                          {action.shortcut && <Kbd>{action.shortcut}</Kbd>}
                        </span>
                      }
                    />
                  ))}
                </Group>
              </>
            )}
          </CommandList>
          <div className="hidden h-10 shrink-0 items-center gap-4 border-t border-border px-4 text-control text-muted-foreground md:flex">
            {frame.products.length > 1 && (
              <span className="flex items-center gap-2"><Kbd>⇥</Kbd>{otherProduct ? "Volver a este producto" : query ? `Buscar «${query}» en otro producto` : "Buscar en otro producto"}</span>
            )}
            <span className="ml-auto flex items-center gap-1.5"><Kbd>↑↓</Kbd>moverte</span>
            <span className="flex items-center gap-1.5"><Kbd>↵</Kbd>abrir</span>
            <span className="flex items-center gap-1.5"><Kbd>esc</Kbd>cerrar</span>
          </div>
        </Command>
      </DialogContent>
    </Dialog>
  )
}

function Group({ label, children }: { label: string; children: ReactNode }) {
  return (
    <CommandGroup className="pb-1.5">
      <CommandGroupLabel className="px-3 pt-3 pb-1.5 font-mono text-[10px] tracking-[0.12em] text-muted-foreground uppercase">{label}</CommandGroupLabel>
      {children}
    </CommandGroup>
  )
}

function Row({ value, label, keywords, lead, code, title, trail }: { value: string; label: string; keywords?: string[]; lead: ReactNode; code?: string; title: string; trail?: ReactNode }) {
  return (
    <CommandItem value={value} label={label} keywords={keywords} className="flex h-10 cursor-default items-center gap-3 rounded-md px-3 text-sm data-highlighted:bg-muted">
      {lead}
      {code && <span className="w-12 shrink-0 truncate font-mono text-label text-muted-foreground">{code}</span>}
      <CommandItemText className={cx("min-w-0 flex-1 truncate text-foreground [&_mark]:bg-transparent [&_mark]:font-semibold [&_mark]:text-foreground")}>{title}</CommandItemText>
      {trail && <span className="shrink-0">{trail}</span>}
    </CommandItem>
  )
}
