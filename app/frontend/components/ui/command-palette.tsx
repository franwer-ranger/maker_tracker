import { router, usePage } from "@inertiajs/react"
import {
  Command,
  CommandEmpty,
  CommandGroup,
  CommandGroupLabel,
  CommandInput,
  CommandItem,
  CommandList,
  CommandStatus,
} from "@ui-sdk/react/command"
import { Dialog, DialogBackdrop, DialogContent, DialogDescription, DialogTitle } from "@ui-sdk/react/dialog"
import { useShortcutHint } from "@ui-sdk/react/shortcuts"
import { fuzzyScore, matchRanges, matchSegments } from "@ui-sdk/react/text-match"
import { type ReactNode, useEffect, useState } from "react"
import { setTheme, useTheme } from "@/lib/theme"
import type { SearchItem } from "@/types"
import { Icon, type IconName } from "./icons"
import { Kbd } from "./kbd"
import { ProductMark } from "./product-combo"
import { StateDot } from "./state-dot"

type Action = { value: string; label: string; icon: IconName; command?: string; shortcut?: string; hint?: string; run: () => void }
type Target = { item: SearchItem; icon: IconName; kind: string; code: boolean }

// Las acciones no se filtran (Paper: siguen debajo de los resultados al buscar); el resto, por letras en orden.
const isAction = (value: string) => value.startsWith("action:")
const score = (label: string, keywords: string[] | undefined, query: string) =>
  Math.max(fuzzyScore(label, query), ...(keywords ?? []).map((keyword) => fuzzyScore(keyword, query) * 0.9))
const searchFilter = (item: { value: string; label: string; keywords?: string[] }, query: string) =>
  isAction(item.value) || score(item.label, item.keywords, query)
const plural = (count: number, one: string, many: string) => `${count} ${count === 1 ? one : many}`

// ⌘K (MT-101, Paper «v1 · 11 · Ventanas y atajos»): ámbito el producto actual. «Ir a» (pantallas, capacidades,
// historias, decisiones) y «Acciones» con su atajo y su comando `mt`, siempre visibles. ⇥ (o «Buscar en otro
// producto» en el móvil) lleva lo escrito a otro producto. Comportamiento de UI SDK (diálogo modal, combobox);
// el índice llega con una recarga parcial al abrir.
export function CommandPalette({ open, onOpenChange, initialQuery = "" }: { open: boolean; onOpenChange: (open: boolean) => void; initialQuery?: string }) {
  const { search, nav, project, frame } = usePage().props
  const [loading, setLoading] = useState(false)
  const [query, setQuery] = useState(initialQuery)
  const [otherProduct, setOtherProduct] = useState(false)
  const theme = useTheme()
  const dark = theme.endsWith(":dark")
  const copyHint = useShortcutHint("mod+shift+c")
  const manyProducts = frame.products.length > 1

  useEffect(() => {
    if (!open) return
    setOtherProduct(false)
    setQuery(initialQuery)
    router.reload({ only: ["search"], onStart: () => setLoading(true), onFinish: () => setLoading(false) })
  }, [open, initialQuery])

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
  const goTo: Target[] = [
    ...screens.map((item) => ({ item, icon: "arrowRight" as IconName, kind: "", code: false })),
    ...(search?.capabilities ?? []).map((item) => ({ item, icon: "file" as IconName, kind: "Capacidad", code: false })),
    ...(search?.stories ?? []).map((item) => ({ item, icon: "stories" as IconName, kind: "Historia", code: true })),
    ...(search?.decisions ?? []).map((item) => ({ item, icon: "decision" as IconName, kind: "Decisión", code: true })),
  ]
  const label = ({ item }: Target) => `${item.ref} ${item.title}`.trim()
  const matches = query ? goTo.filter((target) => score(label(target), [target.item.meta], query) > 0).length : goTo.length
  // Las acciones sin pantalla propia todavía copian su comando `mt` para tu agente. «Apuntar una idea» llevará
  // su atajo N cuando tenga su ventana; hasta entonces no se anuncia un atajo que no hace nada.
  const actions: Action[] = [
    { value: "action:idea", label: "Apuntar una idea", icon: "spark", command: "mt create", run: () => copy(`mt create "…" --project ${project.key}`) },
    { value: "action:story", label: "Nueva historia", icon: "pencil", command: "mt create --state defining", run: () => copy(`mt create "…" --state defining --project ${project.key}`) },
    { value: "action:decision", label: "Nueva decisión", icon: "decision", command: "mt decide", run: () => copy(`mt decide "…" --why "…" --project ${project.key}`) },
    ...(manyProducts ? [{ value: "action:product", label: "Cambiar de producto", icon: "swap" as IconName, shortcut: "P", run: () => setOtherProduct(true) }] : []),
    { value: "action:copy", label: "Copiar para tu agente", icon: "copy", shortcut: copyHint.text, run: () => copy(`mt context --project ${project.key}`) },
    { value: "action:theme", label: "Tema claro / oscuro", icon: "contrast", hint: `Ahora: ${dark ? "oscuro" : "claro"}`, run: () => setTheme(dark ? "light" : "dark") },
  ]

  const run = (value: string) => {
    if (otherProduct) {
      const product = frame.products.find((item) => item.key === value)
      close()
      // Lo escrito viaja al otro producto: su ⌘K se abre con la misma búsqueda.
      if (product) router.visit(query ? `${product.url}?buscar=${encodeURIComponent(query)}` : product.url)
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
    // Lo que aún no es de Inertia (tablero, brief) va con una carga completa.
    if (target.url.startsWith(nav.cover)) router.visit(target.url)
    else window.location.assign(target.url)
  }

  const toggleOtherProduct = () => manyProducts && setOtherProduct((value) => !value)
  const chip = (
    <button
      type="button"
      onClick={toggleOtherProduct}
      aria-label={`Producto: ${project.name}. Cambiar`}
      className="flex shrink-0 items-center gap-[7px] rounded-md border border-border py-1 pr-2 pl-1.5 text-control text-foreground"
    >
      <ProductMark code={project.key} size={16} />
      {project.name}
      {manyProducts && <Icon name="chevronDown" size={12} strokeWidth={2} className="text-muted-foreground" />}
    </button>
  )

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogBackdrop className="fixed inset-0 z-40 bg-overlay transition-opacity data-starting-style:opacity-0 data-ending-style:opacity-0" />
      <DialogContent className="fixed inset-0 z-50 flex flex-col overflow-hidden bg-background text-foreground transition data-starting-style:opacity-0 data-ending-style:opacity-0 md:inset-auto md:top-[13vh] md:left-1/2 md:max-h-[70vh] md:w-[min(680px,calc(100vw-32px))] md:-translate-x-1/2 md:rounded-xl md:border md:border-border md:bg-card md:shadow-[0_16px_40px_rgba(15,15,17,0.18)] md:data-starting-style:scale-[0.98]">
        <DialogTitle className="sr-only">Buscar en {project.name}</DialogTitle>
        <DialogDescription className="sr-only">Capacidades, historias, decisiones y acciones. Flechas para moverte, Enter para abrir, Tab para buscar en otro producto, Escape para cerrar.</DialogDescription>
        <Command
          onAction={run}
          query={query}
          onQueryChange={(value) => setQuery(value)}
          filter={otherProduct ? false : searchFilter}
          status={loading && !search ? "loading" : "idle"}
          className="flex min-h-0 flex-1 flex-col"
          onKeyDown={(event) => {
            if (event.key === "Tab" && !event.shiftKey && manyProducts) {
              event.preventDefault()
              setOtherProduct((value) => !value)
            }
          }}
        >
          <div className="flex shrink-0 items-center gap-3 px-3.5 pt-3.5 pb-3 md:h-14 md:border-b md:border-border md:px-4 md:py-0">
            <div className="flex min-w-0 flex-1 items-center gap-[9px] rounded-[10px] bg-card px-3 py-[9px] ring-[1.5px] ring-foreground md:gap-3 md:rounded-none md:bg-transparent md:p-0 md:ring-0">
              <Icon name="search" size={15} className="shrink-0 text-muted-foreground" />
              <CommandInput
                aria-label={otherProduct ? `Buscar «${query}» en otro producto` : `Buscar en ${project.name}`}
                placeholder={otherProduct ? "Elige el producto…" : "Busca una capacidad, historia o decisión…"}
                className="min-w-0 flex-1 bg-transparent text-base outline-none placeholder:text-muted-foreground focus-visible:shadow-none md:h-full"
              />
            </div>
            <CommandStatus className="hidden font-mono text-label text-muted-foreground md:block">
              {(state) => (state.loading ? "cargando" : otherProduct ? plural(frame.products.length - 1, "producto", "productos") : plural(matches, "resultado", "resultados"))}
            </CommandStatus>
            <span className="hidden md:block">{chip}</span>
            <button type="button" onClick={close} className="shrink-0 text-[15px] leading-[18px] text-foreground md:hidden">Cancelar</button>
          </div>
          <div className="flex shrink-0 items-center justify-between px-4 pb-1.5 md:hidden">
            {chip}
            {manyProducts && (
              <button type="button" onClick={toggleOtherProduct} className="text-control text-muted-foreground underline decoration-border underline-offset-2">
                {otherProduct ? "Volver a este producto" : "Buscar en otro producto"}
              </button>
            )}
          </div>
          {!otherProduct && query && matches === 0 && !(loading && !search) && (
            <p className="px-4 py-6 text-center text-sm text-muted-foreground">Nada coincide con «{query}» en {project.name}.</p>
          )}
          <CommandEmpty className="px-4 py-8 text-center text-sm text-muted-foreground not-data-loading:hidden">Cargando…</CommandEmpty>
          <CommandList className="min-h-0 flex-1 overflow-y-auto p-1.5 max-md:pt-0">
            {otherProduct ? (
              <Group label={query ? `Buscar «${query}» en` : "Otro producto"}>
                {frame.products.filter((product) => product.key !== project.key).map((product) => (
                  <Row key={product.key} value={product.key} label={`${product.name} ${product.key}`} lead={<ProductMark code={product.key} size={16} />} title={product.name} />
                ))}
              </Group>
            ) : (
              <>
                <Group label="Ir a">
                  {goTo.map((target) => {
                    const { item, icon, kind } = target
                    return (
                      <Row
                        key={item.value}
                        value={item.value}
                        label={label(target)}
                        keywords={[item.meta]}
                        lead={<Icon name={icon} size={14} className="text-muted-foreground" />}
                        code={target.code ? item.ref : undefined}
                        title={item.title}
                        query={query}
                        subtitle={[kind, item.meta].filter(Boolean).join(" · ")}
                        trail={
                          <span className="flex items-center gap-1.5 text-control text-muted-foreground">
                            {item.state && <StateDot state={item.state} />}
                            {kind === "Capacidad" ? [kind, item.meta].filter(Boolean).join(" · ") : item.meta}
                          </span>
                        }
                      />
                    )
                  })}
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
            {manyProducts && (
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

// En el móvil (Paper ZIY): título que parte línea y un subtítulo con el tipo y su dato; en escritorio, una línea con el dato a la derecha.
// Con un filtro propio UI SDK no marca lo encontrado: se marca aquí, igual que su búsqueda difusa.
function Row({ value, label, keywords, lead, code, title, query, subtitle, trail }: { value: string; label: string; keywords?: string[]; lead: ReactNode; code?: string; title: string; query?: string; subtitle?: string; trail?: ReactNode }) {
  const segments = query?.trim() ? matchSegments(title, matchRanges(title, query, "fuzzy")) : [{ text: title, match: false }]
  return (
    <CommandItem value={value} label={label} keywords={keywords} className="flex cursor-default items-start gap-3 rounded-lg px-3 py-[11px] text-[15px] leading-5 data-highlighted:bg-muted md:h-10 md:items-center md:rounded-md md:py-0 md:text-sm">
      <span className="shrink-0 pt-0.5 md:pt-0">{lead}</span>
      <span className="flex min-w-0 flex-1 flex-col gap-[3px] md:flex-row md:items-center md:gap-3">
        <span className="min-w-0 md:flex md:flex-1 md:items-center md:gap-3">
          {code && <span className="mr-2 font-mono text-label text-muted-foreground md:mr-0 md:w-12 md:shrink-0 md:truncate">{code}</span>}
          <span className="min-w-0 text-foreground md:flex-1 md:truncate">
            {segments.map((segment, index) => (segment.match ? <mark key={index} className="bg-transparent font-semibold text-foreground">{segment.text}</mark> : segment.text))}
          </span>
        </span>
        {subtitle && <span className="text-xs text-muted-foreground md:hidden">{subtitle}</span>}
      </span>
      {trail && <span className="hidden shrink-0 md:block">{trail}</span>}
    </CommandItem>
  )
}
