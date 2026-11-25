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
import { Dialog, DialogBackdrop, DialogContent, DialogDescription, DialogShortcut, DialogTitle, DialogTrigger } from "@ui-sdk/react/dialog"
import { useState } from "react"
import type { SearchItem } from "@/types"
import { Kbd } from "./kbd"
import { StateDot } from "./state-dot"

const groups = [
  { key: "stories", label: "Historias" },
  { key: "capabilities", label: "Capacidades" },
  { key: "decisions", label: "Decisiones" },
] as const

// ⌘K (MT-99): buscar historias, capacidades y decisiones. Comportamiento y accesibilidad de UI SDK
// (diálogo modal, combobox con listbox, aria-activedescendant); el aspecto, de nuestros tokens.
// El índice llega con una recarga parcial al abrir (prop opcional `search`).
export function CommandPalette() {
  const { search, nav } = usePage().props
  const [open, setOpen] = useState(false)
  const [loading, setLoading] = useState(false)

  const changeOpen = (next: boolean) => {
    setOpen(next)
    if (next) router.reload({ only: ["search"], onStart: () => setLoading(true), onFinish: () => setLoading(false) })
  }

  const items = new Map<string, SearchItem>(groups.flatMap(({ key }) => (search?.[key] ?? []).map((item) => [item.value, item] as const)))

  const go = (value: string) => {
    const item = items.get(value)
    if (!item) return
    setOpen(false)
    // Lo que no es de Inertia (historia, brief) va con una carga completa; lo de la v1, con una visita.
    if (item.url.startsWith(nav.cover)) router.visit(item.url)
    else window.location.assign(item.url)
  }

  return (
    <Dialog open={open} onOpenChange={changeOpen}>
      <DialogTrigger
        shortcut="mod+k"
        className="flex h-8 w-full items-center gap-2 rounded-md border border-sidebar-border px-2.5 text-control text-sidebar-muted transition-colors hover:text-sidebar-foreground"
      >
        <SearchIcon />
        <span className="flex-1 text-left">Buscar</span>
        <DialogShortcut className="rounded-sm bg-sidebar-active px-1 font-mono text-label text-sidebar-foreground" />
      </DialogTrigger>
      <DialogBackdrop className="fixed inset-0 z-40 bg-black/40 transition-opacity data-starting-style:opacity-0 data-ending-style:opacity-0" />
      <DialogContent
        className="fixed top-[12vh] left-1/2 z-50 flex max-h-[70vh] w-[min(640px,calc(100vw-32px))] -translate-x-1/2 flex-col overflow-hidden rounded-xl border border-border bg-popover text-foreground shadow-[0_12px_32px_rgba(15,15,17,0.18)] transition data-starting-style:scale-[0.98] data-starting-style:opacity-0 data-ending-style:opacity-0"
      >
        <DialogTitle className="sr-only">Buscar en el proyecto</DialogTitle>
        <DialogDescription className="sr-only">Historias, capacidades y decisiones. Flechas para moverte, Enter para abrir, Escape para cerrar.</DialogDescription>
        <Command onAction={go} status={loading && !search ? "loading" : "idle"} pendingAnnouncement="Abriendo…" className="flex min-h-0 flex-col">
          <div className="flex h-12 items-center gap-3 border-b border-border px-4">
            <SearchIcon />
            <CommandInput
              aria-label="Buscar historias, capacidades y decisiones"
              placeholder="Busca una historia, capacidad o decisión…"
              className="h-full flex-1 bg-transparent text-sm outline-none placeholder:text-muted-foreground focus-visible:shadow-none"
            />
            <Kbd>esc</Kbd>
          </div>
          <CommandStatus className="sr-only">{(state) => (state.loading ? "Cargando…" : `${state.count} resultados`)}</CommandStatus>
          <CommandEmpty className="px-4 py-8 text-center text-sm text-muted-foreground not-data-empty:not-data-loading:hidden">
            {(state) => (state.loading ? "Cargando…" : state.empty ? `Nada coincide con «${state.query}».` : null)}
          </CommandEmpty>
          <CommandList className="min-h-0 overflow-y-auto p-2">
            {groups.map(({ key, label }) => (
              <CommandGroup key={key} className="pb-2">
                <CommandGroupLabel className="px-2 pt-2 pb-1 font-mono text-label uppercase tracking-label text-muted-foreground">{label}</CommandGroupLabel>
                {(search?.[key] ?? []).map((item) => (
                  <CommandItem
                    key={item.value}
                    value={item.value}
                    label={`${item.ref} ${item.title}`}
                    keywords={[item.meta]}
                    className="flex h-9 cursor-default items-center gap-3 rounded-md px-2 text-sm data-highlighted:bg-muted"
                  >
                    {key === "stories" ? <StateDot state={item.state} /> : <span className="size-1.5" aria-hidden="true" />}
                    <span className="w-20 shrink-0 truncate font-mono text-control text-muted-foreground">{item.ref}</span>
                    <CommandItemText className="min-w-0 flex-1 truncate text-foreground [&_mark]:bg-transparent [&_mark]:font-semibold [&_mark]:text-foreground">
                      {item.title}
                    </CommandItemText>
                    <span className="shrink-0 font-mono text-label text-muted-foreground">{item.meta}</span>
                  </CommandItem>
                ))}
              </CommandGroup>
            ))}
          </CommandList>
          <div className="flex h-9 items-center gap-4 border-t border-border px-4 text-label text-muted-foreground">
            <span className="flex items-center gap-1.5"><Kbd>↑</Kbd><Kbd>↓</Kbd> moverte</span>
            <span className="flex items-center gap-1.5"><Kbd>↵</Kbd> abrir</span>
            <span className="ml-auto font-mono">mt show {"<id>"}</span>
          </div>
        </Command>
      </DialogContent>
    </Dialog>
  )
}

function SearchIcon() {
  return (
    <svg aria-hidden="true" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={1.5} className="size-4 shrink-0">
      <path strokeLinecap="round" strokeLinejoin="round" d="m21 21-5.197-5.197m0 0A7.5 7.5 0 1 0 5.196 5.196a7.5 7.5 0 0 0 10.607 10.607Z" />
    </svg>
  )
}
