import { Link, router, usePage } from "@inertiajs/react"
import { Dialog, DialogBackdrop, DialogClose, DialogContent, DialogDescription, DialogTitle } from "@ui-sdk/react/dialog"
import { Input } from "@ui-sdk/react/input"
import { SegmentedControl, SegmentedControlIndicator, SegmentedControlItem } from "@ui-sdk/react/segmented-control"
import { useShortcut } from "@ui-sdk/react/shortcuts"
import { Textarea } from "@ui-sdk/react/textarea"
import { type ReactNode, useEffect, useMemo, useRef, useState } from "react"
import { Board, BoardCard, BoardColumn } from "@/components/ui/board"
import { Button } from "@/components/ui/button"
import { Combo } from "@/components/ui/combo"
import { CopyForAgent } from "@/components/ui/copy-for-agent"
import { cx } from "@/components/ui/cx"
import { DotIllustration, type Figure } from "@/components/ui/dot-illustration"
import { EmptyState } from "@/components/ui/empty-state"
import { Eyebrow } from "@/components/ui/eyebrow"
import { Icon, iconFor } from "@/components/ui/icons"
import { Kbd } from "@/components/ui/kbd"
import { PageHeader } from "@/components/ui/page-header"
import { StateDot } from "@/components/ui/state-dot"
import { states, type StoryState } from "@/components/ui/state"
import { AppShell } from "@/layouts/app-shell"

type Capability = { slug: string; title: string; icon: string | null }

type Item = {
  number: number
  ref: string
  title: string
  state: StoryState
  capabilities: Capability[]
  waiting: { kind: "you" } | { kind: "stories"; refs: string[] } | null
  building: { actor: string; agent: boolean } | null
  milestone: string | null
  closed_on: string | null
  closed_at: string | null
  url: string
  move_url: string
  position_url: string
}

type Group = { id: number; code: string; title: string; closed: boolean; done: number; total: number; items: Item[] }

type ListProps = {
  groups: Group[]
  ideas: Item[]
  capabilities: Capability[]
  open: number
  done: number
  create_url: string
  roadmap_url: string
  copy: string
}

type Status = "open" | "done" | "all"

const ALL = "__all"
const statuses: { value: Status; label: string }[] = [
  { value: "open", label: "Abiertas" },
  { value: "done", label: "Hechas" },
  { value: "all", label: "Todas" },
]
// Filas visibles antes de «+ N más»: la bandeja se pliega siempre; los hitos, solo en móvil (Paper).
const IDEAS = { desktop: 3, mobile: 2 }
const MILESTONE = { desktop: Infinity, mobile: 4 }

const normalize = (text: string) => text.normalize("NFD").replace(/[̀-ͯ]/g, "").toLowerCase()

type View = "list" | "board"
const VIEW_KEY = "maker-tracker:stories-view"

// La vista elegida se recuerda en este navegador (D-103: Lista por defecto). En móvil no hay Tablero.
function useView() {
  const [view, setView] = useState<View>(() => {
    try { return localStorage.getItem(VIEW_KEY) === "board" ? "board" : "list" } catch { return "list" }
  })
  const [wide, setWide] = useState(() => typeof window !== "undefined" && window.matchMedia("(min-width: 768px)").matches)
  useEffect(() => {
    const query = window.matchMedia("(min-width: 768px)")
    const update = () => setWide(query.matches)
    update()
    query.addEventListener("change", update)
    return () => query.removeEventListener("change", update)
  }, [])
  const choose = (next: View) => {
    setView(next)
    try { localStorage.setItem(VIEW_KEY, next) } catch { /* sin almacenamiento: no se recuerda */ }
  }
  return [wide ? view : "list", choose] as const
}

// Historias (MT-109 · «v1 · 8 · Historias»): la Lista por hito en el orden del roadmap y la bandeja de ideas al
// final. Buscador (/), Abiertas/Hechas/Todas y combo de capacidad (en móvil, los filtros en combos). «Apuntar una
// idea» (N) la deja en la bandeja. El Tablero (MT-120) es la misma página por estado. En escritorio y con las abiertas
// sin filtrar, las historias de los hitos se reordenan arrastrando (MT-121, `mt reorder`); la bandeja no tiene orden.
export default function Stories({ stories }: { stories: ListProps }) {
  const { project } = usePage().props
  const [creating, setCreating] = useState(false)
  const [view, setView] = useView()
  useShortcut("n", () => setCreating(true), { description: "Apuntar una idea" })

  const actions = (
    <>
      <CopyForAgent text={stories.copy} shortcut="mod+shift+c" />
      <button type="button" onClick={() => setCreating(true)} className="inline-flex h-8 items-center gap-[7px] rounded-md px-2 text-control text-muted-foreground hover:text-foreground">
        <Icon name="pencil" size={14} />Nueva historia<Kbd className="max-md:hidden">N</Kbd>
      </button>
    </>
  )
  const empty = stories.groups.every((group) => group.items.length === 0) && stories.ideas.length === 0

  return (
    <AppShell title={`Historias · ${project.name}`} active="stories" crumbs={[{ label: "Historias" }]} copy={stories.copy} actions={actions}>
      {empty ? (
        <div className="flex flex-1 items-center justify-center px-5 py-11">
          <EmptyState figure="cards" title="Aún no hay historias" actions={<Button shortcut="N" onClick={() => setCreating(true)}>Apuntar una idea</Button>}>
            Una historia es un cambio en el producto. Empieza apuntando una idea; ya le pondrás hito.
          </EmptyState>
        </div>
      ) : view === "board" ? (
        <div className="flex min-w-0 flex-col gap-7 px-5 pt-6 pb-8 lg:pt-12 lg:pr-10 lg:pb-14 lg:pl-14">
          <StoryBoard stories={stories} onView={setView} />
        </div>
      ) : (
        <div className="flex justify-center px-5 pt-6 pb-8 lg:px-12 lg:pt-[52px] lg:pb-14">
          <div className="flex w-full min-w-0 flex-col gap-[22px] lg:max-w-[860px] lg:gap-7">
            <List stories={stories} onCreate={() => setCreating(true)} onView={setView} />
          </div>
        </div>
      )}
      <NewIdea open={creating} onOpenChange={setCreating} url={stories.create_url} />
    </AppShell>
  )
}

function List({ stories, onCreate, onView }: { stories: ListProps; onCreate: () => void; onView: (view: View) => void }) {
  const { project } = usePage().props
  const [query, setQuery] = useState("")
  const [status, setStatus] = useState<Status>("open")
  const [capability, setCapability] = useState(ALL)

  const words = useWords(query)
  const keep = (item: Item) => {
    if (status === "open" && item.state === "done") return false
    if (status === "done" && item.state !== "done") return false
    if (capability !== ALL && !item.capabilities.some((cap) => cap.slug === capability)) return false
    const haystack = normalize(`${item.ref} ${item.title}`)
    return words.every((word) => haystack.includes(word))
  }
  const groups = stories.groups.map((group) => ({ ...group, shown: group.items.filter(keep) })).filter((group) => group.shown.length > 0)
  const ideas = stories.ideas.filter(keep)
  const filtering = words.length > 0 || capability !== ALL
  // La bandeja se queda aunque esté vacía (con su estado vacío), salvo si se buscan las hechas o se filtra.
  const showTray = ideas.length > 0 || (!filtering && status !== "done")
  const capabilityOptions = [{ value: ALL, label: "Capacidad" }, ...stories.capabilities.map((cap) => ({ value: cap.slug, label: cap.title }))]
  // «Quitar el filtro» lo quita todo, también el estado: pasa a Todas («para verlas todas»).
  const clear = () => { setQuery(""); setCapability(ALL); setStatus("all") }
  // Se reordena lo que se ve entero: las abiertas, sin buscar ni filtrar, y en escritorio (en móvil no hay arrastre).
  const sortable = useWide() && status === "open" && !filtering && groups.length > 0

  return (
    <>
      <PageHeader
        eyebrow={`${project.name} · ${stories.open} ${stories.open === 1 ? "abierta" : "abiertas"} · ${stories.done} ${stories.done === 1 ? "hecha" : "hechas"}`}
        title="Historias"
        lead={<span className="hidden md:inline">{sortable ? "En el orden del roadmap. Arrastra una historia para cambiar su orden en el hito o llevarla a otro." : "En el orden del roadmap. Lo construido se cuenta en el relato; aquí está lo que queda."}</span>}
      />

      <div className="flex items-center gap-2 md:gap-2.5">
        <SearchBox query={query} onQuery={setQuery} className="flex-1" />
        <ViewToggle view="list" onView={onView} />
        <SegmentedControl aria-label="Estado" value={status} onValueChange={(next) => setStatus(next as Status)} className="relative isolate hidden gap-0.5 rounded-lg bg-muted p-[3px] md:inline-flex">
          <SegmentedControlIndicator className="absolute top-(--segmented-control-indicator-top) left-(--segmented-control-indicator-left) -z-10 h-(--segmented-control-indicator-height) w-(--segmented-control-indicator-width) rounded-md bg-card shadow-[0_0_0_1px_var(--color-border)] transition-[left,width] duration-200 data-[activation-direction=none]:transition-none" />
          {statuses.map((option) => (
            <SegmentedControlItem key={option.value} value={option.value} className="rounded-md px-2.5 py-[5px] text-control leading-4 text-muted-foreground data-checked:text-foreground">
              {option.label}
            </SegmentedControlItem>
          ))}
        </SegmentedControl>
        <Combo label="Estado" value={status} options={statuses} onChange={(next) => setStatus(next as Status)} className="shrink-0 md:hidden" />
        <Combo label="Capacidad" value={capability} options={capabilityOptions} onChange={setCapability} className="hidden md:flex" />
        <Combo
          label="Capacidad"
          value={capability}
          options={capabilityOptions}
          onChange={setCapability}
          className={cx("size-[38px] shrink-0 justify-center p-0 md:hidden", capability !== ALL && "border-ring")}
          trigger={<Icon name="filter" size={15} strokeWidth={1.7} />}
        />
      </div>

      {groups.length === 0 && !showTray && (
        <EmptyState
          figure="search"
          title={emptyTitle(query, stories.capabilities.find((cap) => cap.slug === capability)?.title)}
          actions={<Button variant="secondary" onClick={clear}>Quitar el filtro</Button>}
        >
          Quita el filtro para verlas todas.
        </EmptyState>
      )}

      {sortable ? <SortableGroups groups={groups} /> : groups.map((group) => (
        <Section key={group.code} heading={<MilestoneHeading group={group} />} meta={`${group.done} de ${group.total}`} items={group.shown} fold={filtering ? null : MILESTONE} />
      ))}

      {showTray && (
        <Section
          heading={<><Icon name="spark" size={14} className="hidden text-muted-foreground lg:block" /><span className="text-base leading-5 font-medium text-foreground lg:text-lg lg:leading-[22px]">Bandeja de ideas</span></>}
          meta={<>{ideas.length}<span className="hidden lg:inline"> · sin hito ni orden</span></>}
          items={ideas}
          fold={filtering ? null : IDEAS}
          onCreate={onCreate}
          empty={
            <div className="border-t border-border">
              <EmptyState figure="spark" title="Sin ideas en la bandeja" actions={<Button variant="secondary" onClick={onCreate}>Apuntar una idea</Button>}>
                Lo que se te ocurra y aún no tenga sitio, apúntalo aquí.
              </EmptyState>
            </div>
          }
        />
      )}
    </>
  )
}

function MilestoneHeading({ group }: { group: Group }) {
  return (
    <>
      <span className="font-mono text-label leading-[14px] text-muted-foreground lg:text-xs lg:leading-4">{group.code}</span>
      <span className="text-base leading-5 font-medium text-foreground lg:text-lg lg:leading-[22px]">{group.title}</span>
    </>
  )
}

// Escritorio: la Lista de fila con código a la izquierda (lg). Es donde se puede arrastrar.
function useWide() {
  const [wide, setWide] = useState(() => typeof window !== "undefined" && window.matchMedia("(min-width: 1024px)").matches)
  useEffect(() => {
    const query = window.matchMedia("(min-width: 1024px)")
    const update = () => setWide(query.matches)
    update()
    query.addEventListener("change", update)
    return () => query.removeEventListener("change", update)
  }, [])
  return wide
}

const useWords = (query: string) => useMemo(() => normalize(query).split(/\s+/).filter(Boolean), [query])

function SearchBox({ query, onQuery, className }: { query: string; onQuery: (query: string) => void; className?: string }) {
  const search = useRef<HTMLInputElement>(null)
  useShortcut("/", () => search.current?.focus(), { description: "Buscar historias" })
  return (
    <label className={cx("flex min-w-0 items-center gap-2 rounded-lg border border-border bg-card px-3 py-[9px] text-muted-foreground focus-within:border-ring md:py-2", className)}>
      <Icon name="search" size={14} strokeWidth={1.8} />
      <Input ref={search} value={query} onValueChange={(value) => onQuery(value)} aria-label="Buscar historias" placeholder="Buscar historias…" className="min-w-0 flex-1 bg-transparent text-sm leading-[18px] text-foreground outline-none placeholder:text-muted-foreground focus-visible:shadow-none" />
      <Kbd className="max-md:hidden">/</Kbd>
    </label>
  )
}

const views: { value: View; label: string; icon: "stories" | "board" }[] = [
  { value: "list", label: "Lista", icon: "stories" },
  { value: "board", label: "Tablero", icon: "board" },
]

// Lista / Tablero (D-103): la misma página, dos vistas. En móvil no hay Tablero y no se enseña.
function ViewToggle({ view, onView }: { view: View; onView: (view: View) => void }) {
  return (
    <SegmentedControl aria-label="Vista" value={view} onValueChange={(next) => onView(next as View)} className="relative isolate hidden shrink-0 gap-0.5 rounded-lg bg-muted p-[3px] md:inline-flex">
      <SegmentedControlIndicator className="absolute top-(--segmented-control-indicator-top) left-(--segmented-control-indicator-left) -z-10 h-(--segmented-control-indicator-height) w-(--segmented-control-indicator-width) rounded-md bg-card shadow-[0_0_0_1px_var(--color-border)] transition-[left,width] duration-200 data-[activation-direction=none]:transition-none" />
      {views.map((option) => (
        <SegmentedControlItem key={option.value} value={option.value} className="flex items-center gap-1.5 rounded-md px-2.5 py-[5px] text-control leading-4 text-muted-foreground data-checked:text-foreground">
          <Icon name={option.icon} size={14} strokeWidth={1.7} />
          {option.label}
        </SegmentedControlItem>
      ))}
    </SegmentedControl>
  )
}

type ColumnKey = "idea" | "defining" | "ready" | "done"
type Lists = Record<string, string[]>

// Las columnas del Tablero (Paper): sin «En curso», que es Lista con la marca «en construcción». Antes de
// «+ N más» se ven unas pocas; Hecha enseña las últimas y lleva al relato.
const columns: { key: ColumnKey; label: string; fold: number; figure: Figure; empty: [string, string] }[] = [
  { key: "idea", label: "Idea", fold: 3, figure: "spark", empty: ["Sin ideas por definir.", "Lo que apuntes con N cae aquí."] },
  { key: "defining", label: "Definiendo", fold: 4, figure: "pencil", empty: ["Nada en definición.", "Cuando empieces a escribir una idea, pasa aquí."] },
  { key: "ready", label: "Lista", fold: 4, figure: "flag", empty: ["Nada listo para construir.", "Cuando una historia esté definida, pasa aquí."] },
  { key: "done", label: "Hecha", fold: 3, figure: "calm", empty: ["Aún no hay nada hecho.", "Lo que se termine se cuenta en el relato."] },
]
const columnOf = (state: StoryState): ColumnKey => (state === "in_progress" ? "ready" : state)
const NO_MILESTONE = "__none"

// El Tablero (MT-120 · «v1 · 8 · Historias · Tablero»): las mismas historias por estado. Arrastrar una tarjeta
// a otra columna es `mt move`: lo decide el servidor y, si no se puede, la tarjeta vuelve y el aviso dice por qué.
function StoryBoard({ stories, onView }: { stories: ListProps; onView: (view: View) => void }) {
  const { project } = usePage().props
  const [query, setQuery] = useState("")
  const [capability, setCapability] = useState(ALL)
  const [milestone, setMilestone] = useState(ALL)
  const [expanded, setExpanded] = useState<Partial<Record<ColumnKey, boolean>>>({})
  const [pending, setPending] = useState<Lists | null>(null)
  const dropped = useRef(0)
  const words = useWords(query)

  const keep = (item: Item) => {
    if (capability !== ALL && !item.capabilities.some((cap) => cap.slug === capability)) return false
    if (milestone === NO_MILESTONE ? item.milestone !== null : milestone !== ALL && item.milestone !== milestone) return false
    const haystack = normalize(`${item.ref} ${item.title}`)
    return words.every((word) => haystack.includes(word))
  }
  const all = useMemo(() => [...stories.groups.flatMap((group) => group.items), ...stories.ideas], [stories])
  const byRef = useMemo(() => new Map(all.map((item) => [item.ref, item])), [all])
  const shown = all.filter(keep)
  const byColumn = Object.fromEntries(columns.map((column) => [column.key, shown.filter((item) => columnOf(item.state) === column.key)])) as Record<ColumnKey, Item[]>
  byColumn.done.sort((a, b) => (b.closed_at ?? "").localeCompare(a.closed_at ?? ""))
  const lists: Lists = Object.fromEntries(columns.map((column) => {
    const items = byColumn[column.key]
    return [column.key, (expanded[column.key] ? items : items.slice(0, column.fold)).map((item) => item.ref)]
  }))

  const move = (value: Lists, details: { key: string; from: string; to: string; cancel: () => void }) => {
    const item = byRef.get(details.key)
    if (!item || details.from === details.to) {
      details.cancel()
      return
    }
    dropped.current = Date.now()
    setPending(value)
    router.post(item.move_url, { state: details.to }, { preserveScroll: true, onFinish: () => setPending(null) })
  }

  const milestoneOptions = [
    { value: ALL, label: "Todos los hitos" },
    ...stories.groups.map((group) => ({ value: group.code, label: `${group.code} · ${group.title}` })),
    { value: NO_MILESTONE, label: "Sin hito" },
  ]
  const capabilityOptions = [{ value: ALL, label: "Capacidad" }, ...stories.capabilities.map((cap) => ({ value: cap.slug, label: cap.title }))]

  return (
    <>
      <div className="max-w-[860px]">
        <PageHeader
          eyebrow={`${project.name} · ${stories.open} ${stories.open === 1 ? "abierta" : "abiertas"} · ${stories.done} ${stories.done === 1 ? "hecha" : "hechas"}`}
          title="Historias"
          lead="La misma lista, por estado. Para ver de un vistazo qué falta definir y qué está listo."
        />
      </div>

      <div className="flex items-center gap-2.5">
        <SearchBox query={query} onQuery={setQuery} className="w-[360px] shrink" />
        <ViewToggle view="board" onView={onView} />
        <span className="flex-1" />
        <Combo label="Hito" value={milestone} options={milestoneOptions} onChange={setMilestone} className="shrink-0" />
        <Combo label="Capacidad" value={capability} options={capabilityOptions} onChange={setCapability} className="shrink-0" />
      </div>

      <Board
        value={pending ?? lists}
        order={() => columns.map((column) => column.key)}
        label={(key: string) => byRef.get(key)?.title}
        listLabel={(list: string) => columns.find((column) => column.key === list)?.label}
        onValueChange={move}
        aria-label="Historias por estado"
        className="flex items-start gap-3.5"
      >
        {({ lists: current }: { lists: Lists }) => {
          return columns.map((column) => {
            const refs = current[column.key] ?? []
            const total = byColumn[column.key].length
            const hidden = expanded[column.key] ? 0 : Math.max(total - column.fold, 0)
            return (
              <section key={column.key} aria-label={column.label} className="flex w-0 grow basis-0 flex-col gap-2.5">
                <h2 className="flex items-center justify-between px-0.5 pb-1">
                  <span className="flex items-center gap-2 text-control leading-4 font-medium text-foreground">
                    <StateDot state={column.key} className="size-[7px]" />
                    {column.label}
                  </span>
                  <span className="font-mono text-label leading-[14px] text-muted-foreground">{total}</span>
                </h2>
                <BoardColumn value={column.key} className="flex min-h-[120px] flex-col gap-2.5">
                  {refs.length === 0 && <EmptyColumn figure={column.figure} lines={column.empty} />}
                  {refs.map((ref) => {
                    const item = byRef.get(ref)
                    return item && <Card key={ref} item={item} dropped={dropped} />
                  })}
                </BoardColumn>
                {(hidden > 0 || (column.key === "done" && total > 0)) && (
                  <p className="p-0.5 text-xs leading-4 text-muted-foreground">
                    {hidden > 0 && <button type="button" onClick={() => setExpanded((now) => ({ ...now, [column.key]: true }))} className="hover:text-foreground">+ {hidden} más</button>}
                    {column.key === "done" && (
                      <>
                        {hidden > 0 && " · "}
                        <Link href={stories.roadmap_url} className="underline decoration-1 underline-offset-2 hover:text-foreground">Ver en el relato</Link>
                      </>
                    )}
                  </p>
                )}
              </section>
            )
          })
        }}
      </Board>
    </>
  )
}

// Columna vacía (Paper): la ilustración de puntos pequeña y su frase, en un recuadro con borde.
function EmptyColumn({ figure, lines }: { figure: Figure; lines: [string, string] }) {
  return (
    <div className="flex flex-col items-center gap-3 rounded-[10px] px-4 py-7 shadow-[inset_0_0_0_1px_var(--color-border)]">
      <DotIllustration figure={figure} size={56} />
      <p className="text-center text-xs leading-[18px] text-muted-foreground">{lines[0]}<br />{lines[1]}</p>
    </div>
  )
}

// Tarjeta (Paper): código y hito (o la fecha, si está hecha), título y por qué espera o «en construcción».
// Es un enlace a la historia; Espacio la coge para moverla con el teclado.
function Card({ item, dropped }: { item: Item; dropped: { current: number } }) {
  const parts = waitingParts(item)
  return (
    <BoardCard
      value={item.ref}
      render={<Link href={item.url} draggable={false} />}
      onClickCapture={(event: React.MouseEvent) => { if (Date.now() - dropped.current < 400) event.preventDefault() }}
      className="flex cursor-grab flex-col gap-2 rounded-[10px] bg-card px-[13px] py-3 shadow-[0_0_0_1px_var(--color-border)] hover:shadow-[0_0_0_1px_var(--color-kbd)] data-dragging:opacity-40 data-grabbed:outline-1 data-grabbed:outline-foreground data-drag-preview:shadow-[0_0_0_1px_var(--color-border),0_12px_32px_rgba(15,15,17,0.14)]"
    >
      <span className="flex items-center justify-between font-mono text-label leading-[14px] text-muted-foreground">
        <span>{item.ref}</span>
        <span>{item.closed_on ?? item.milestone ?? "sin hito"}</span>
      </span>
      <span className="text-sm leading-5 text-foreground">{item.title}</span>
      {parts.length > 0 && (
        <span className="flex flex-wrap items-center gap-x-1 text-xs leading-4 text-muted-foreground">
          {parts.map((part, index) => <span key={index} className="inline-flex items-center gap-1">{index > 0 && "·"}{part}</span>)}
        </span>
      )}
    </BoardCard>
  )
}

function emptyTitle(query: string, capability: string | undefined) {
  if (query.trim()) return `Ninguna historia con «${query.trim()}»`
  if (capability) return `Ninguna historia cambia «${capability}»`
  return "Ninguna historia aquí"
}

// Un hito (o la bandeja): cabecera con su código y avance, filas y, si se pliega, «+ N más».
function Section({ heading, meta, items, fold, onCreate, empty, rows }: {
  heading: ReactNode
  meta: ReactNode
  items: Item[]
  fold: { desktop: number; mobile: number } | null
  onCreate?: () => void
  empty?: ReactNode
  rows?: ReactNode
}) {
  const [expanded, setExpanded] = useState(false)
  const limit = expanded || !fold ? { desktop: Infinity, mobile: Infinity } : fold
  const hiddenDesktop = Math.max(items.length - limit.desktop, 0)
  const hiddenMobile = Math.max(items.length - limit.mobile, 0)

  return (
    <section className="flex flex-col">
      <h2 className="flex items-baseline justify-between gap-3 pb-2 lg:pb-2.5">
        <span className="flex min-w-0 items-baseline gap-2.5 lg:items-center lg:gap-3">{heading}</span>
        <span className="shrink-0 font-mono text-label leading-[14px] text-muted-foreground">{meta}</span>
      </h2>
      {items.length === 0 && empty}
      {rows ?? items.map((item, index) => (
        <Row key={item.number} item={item} className={cx(index >= limit.mobile && "max-lg:hidden", index >= limit.desktop && "lg:hidden")} />
      ))}
      {(hiddenDesktop > 0 || hiddenMobile > 0 || (onCreate && items.length > 0)) && (
        <p className="pt-2 text-control leading-4 text-muted-foreground lg:pt-2.5">
          {hiddenMobile > 0 && <button type="button" onClick={() => setExpanded(true)} className="hover:text-foreground lg:hidden">+ {hiddenMobile} más</button>}
          {hiddenDesktop > 0 && <button type="button" onClick={() => setExpanded(true)} className="hidden hover:text-foreground lg:inline">+ {hiddenDesktop} más</button>}
          {onCreate && items.length > 0 && (
            <>
              {hiddenMobile > 0 && <span className="lg:hidden"> · </span>}
              {hiddenDesktop > 0 && <span className="hidden lg:inline"> · </span>}
              <button type="button" onClick={onCreate} className="underline decoration-1 underline-offset-2 hover:text-foreground">Apuntar una idea</button>
            </>
          )}
        </p>
      )}
    </section>
  )
}

// Fila (Paper): código en mono, título, capacidades con icono y por qué espera; a la derecha, el estado.
// En móvil, el estado baja a la línea de abajo, junto al código.
function Row({ item, className }: { item: Item; className?: string }) {
  return (
    <Link
      href={item.url}
      className={cx(
        "flex flex-col gap-[5px] border-t border-border py-[13px] hover:bg-card/60 lg:grid lg:grid-cols-[60px_1fr_auto] lg:items-center lg:gap-3.5 lg:px-0",
        className,
      )}
    >
      <RowBody item={item} />
    </Link>
  )
}

function RowBody({ item }: { item: Item }) {
  const label = states[item.state]?.label ?? item.state
  return (
    <>
      <span className="hidden font-mono text-xs leading-4 text-muted-foreground lg:block">{item.ref}</span>
      <span className="flex min-w-0 flex-col gap-[5px]">
        <span className="text-[15px] leading-[21px] text-foreground">{item.title}</span>
        <span className="flex flex-wrap items-center gap-x-2 gap-y-1 text-xs leading-4 text-muted-foreground lg:gap-x-3.5">
          <span className="flex items-center gap-2 lg:hidden">
            <StateDot state={item.state} />
            <Eyebrow className="tracking-normal">{item.ref} · {label}</Eyebrow>
          </span>
          {item.capabilities.map((cap) => (
            <span key={cap.slug} className="hidden items-center gap-[5px] lg:flex">
              <Icon name={iconFor(cap.icon)} size={12} strokeWidth={1.6} />
              {cap.title}
            </span>
          ))}
          <Waiting item={item} />
        </span>
      </span>
      <span className="hidden items-center gap-[7px] text-xs leading-4 text-foreground lg:flex">
        <StateDot state={item.state} className="size-[7px]" />
        {label}
      </span>
    </>
  )
}

type Target = { before: number } | { after: number } | { milestone: number }
type Move = { item: Item; lists: Lists; target: Target; back: Target; sentence: ReactNode; command: string }
type Shown = Group & { shown: Item[] }

const SETTLE_MS = 8000
const csrf = () => document.querySelector<HTMLMetaElement>("meta[name=csrf-token]")?.content ?? ""

// Reordenar (MT-121 · «Historias · Lista · Arrastrando» y «Tras soltar»): es `mt reorder` (Stories::PositionsController,
// `story.reorder!` con su evento); el servidor decide. Al soltar, la fila se queda donde cae y se pide el motivo: se
// manda al guardar, o sin motivo cuando el aviso se cierra solo. Deshacer (⌘Z) antes de eso la devuelve sin tocar nada;
// después, la vuelve a mover a su sitio como otro `mt reorder`, que queda en el historial.
function SortableGroups({ groups }: { groups: Shown[] }) {
  const byRef = useMemo(() => new Map(groups.flatMap((group) => group.items.map((item) => [item.ref, item]))), [groups])
  const groupOf = (code: string) => groups.find((group) => group.code === code)
  const lists: Lists = Object.fromEntries(groups.map((group) => [group.code, group.shown.map((item) => item.ref)]))
  const [shown, setShown] = useState<Lists | null>(null)
  const [pending, setPending] = useState<Move | null>(null)
  const [done, setDone] = useState<Move | null>(null)
  const [reason, setReason] = useState("")
  const [error, setError] = useState<string | null>(null)
  const pendingRef = useRef<Move | null>(null)
  const queue = useRef<Promise<unknown>>(Promise.resolve())
  const visits = useRef(0)
  const dropped = useRef(0)
  pendingRef.current = pending

  // Una petición detrás de otra, en el orden en que se soltaron; al acabar, la Lista vuelve a ser la del servidor.
  const send = (item: Item, target: Target, motive?: string) => {
    const visit = ++visits.current
    queue.current = queue.current.then(async () => {
      const response = await fetch(item.position_url, {
        method: "PATCH",
        keepalive: true,
        headers: { Accept: "application/json", "Content-Type": "application/json", "X-CSRF-Token": csrf() },
        body: JSON.stringify({ ...target, reason: motive?.trim() || undefined }),
      })
      if (!response.ok) throw new Error((await response.json().catch(() => null))?.error ?? `${item.ref} no se ha movido.`)
    }).then(() => true, (problem: Error) => { setError(problem.message); return false })
      .finally(() => router.reload({ only: ["stories"], onFinish: () => { if (visit === visits.current) setShown(null) } }))
    return queue.current as Promise<boolean>
  }

  const commit = (motive?: string) => {
    const move = pendingRef.current
    if (!move) return
    pendingRef.current = null
    setPending(null)
    setReason("")
    send(move.item, move.target, motive).then((ok) => setDone(ok ? move : null))
  }

  const undo = () => {
    if (pendingRef.current) {
      pendingRef.current = null
      setPending(null)
      setReason("")
      setShown(null)
    } else if (done) {
      setDone(null)
      send(done.item, done.back)
    }
  }
  useShortcut("mod+z", undo, { description: "Deshacer el último orden", when: () => (pending !== null && reason === "") || (pending === null && done !== null) })

  // Sin motivo también vale: se cierra solo (y se manda) si no se escribe nada. Al irse de la página, se manda ya.
  useEffect(() => {
    if (!pending || reason !== "") return
    const timer = window.setTimeout(() => commit(), SETTLE_MS)
    return () => window.clearTimeout(timer)
  }, [pending, reason])
  useEffect(() => {
    const leave = () => commit()
    const off = router.on("before", leave)
    window.addEventListener("pagehide", leave)
    return () => { off(); window.removeEventListener("pagehide", leave) }
  }, [])

  const number = (ref: string) => byRef.get(ref)!.number
  // Dónde queda una fila: detrás de la de arriba, delante de la de abajo o, si está sola, al final del hito.
  const place = (list: string[], ref: string, code: string): Target => {
    const index = list.indexOf(ref)
    const [above, below] = [list[index - 1], list[index + 1]]
    return above ? { after: number(above) } : below ? { before: number(below) } : { milestone: groupOf(code)!.id }
  }
  const describe = (list: string[], ref: string, code: string) => {
    const index = list.indexOf(ref)
    const [above, below] = [list[index - 1], list[index + 1]]
    return above ? <>detrás de <Mono>{above}</Mono></> : below ? <>delante de <Mono>{below}</Mono></> : <>en <Mono>{code}</Mono></>
  }

  const drop = (value: Lists, details: { key: string; from: string; to: string; index: number; cancel?: () => void }) => {
    const current = shown ?? lists
    const item = byRef.get(details.key)
    const group = groupOf(details.to)
    if (!item || !group || (details.from === details.to && current[details.from].indexOf(details.key) === details.index)) return
    if (pendingRef.current) commit()
    dropped.current = Date.now()
    const list = value[details.to]
    const target = place(list, details.key, details.to)
    // La posición que imprime `mt reorder`: entre todas las del hito, también las hechas que aquí no se ven.
    const all = group.items.map((other) => other.ref).filter((ref) => ref !== details.key)
    const above = list[list.indexOf(details.key) - 1]
    const below = list[list.indexOf(details.key) + 1]
    const position = (above ? all.indexOf(above) + 1 : below ? all.indexOf(below) : all.length) + 1
    const elsewhere = details.from !== details.to
    setShown(value)
    setError(null)
    setDone(null)
    setPending({
      item,
      lists: value,
      target,
      back: place(current[details.from], details.key, details.from),
      sentence: <><Mono>{item.ref}</Mono> va ahora {describe(list, details.key, details.to)}{elsewhere && !("milestone" in target) && <> en <Mono>{details.to}</Mono></>}</>,
      command: `mt reorder ${item.ref} --position ${position}${elsewhere ? ` --milestone ${details.to}` : ""} --reason "…"`,
    })
  }

  return (
    <>
      <Board
        value={shown ?? lists}
        order={() => groups.map((group) => group.code)}
        label={(key: string) => byRef.get(key)?.title}
        listLabel={(list: string) => groupOf(list)?.title}
        onValueChange={drop}
        aria-label="Historias por hito"
        aria-roledescription="lista ordenable"
        className="flex flex-col gap-[22px] lg:gap-7"
      >
        {({ lists: current, moving }: { lists: Lists; moving: string | null }) => {
          const code = moving ? Object.keys(current).find((list) => current[list].includes(moving)) : undefined
          return (
            <>
              {groups.map((group) => (
                <Section
                  key={group.code}
                  heading={<MilestoneHeading group={group} />}
                  meta={`${group.done} de ${group.total}`}
                  items={group.shown}
                  fold={null}
                  rows={
                    <BoardColumn value={group.code} className="flex min-h-[46px] flex-col border-t border-border">
                      {(current[group.code] ?? []).map((ref, index) => {
                        const item = byRef.get(ref)
                        return item && <SortableRow key={ref} item={item} first={index === 0} moved={pending?.item.ref === ref} dropped={dropped} />
                      })}
                    </BoardColumn>
                  }
                />
              ))}
              {moving && code && (
                <Notice>
                  <span className="flex items-center gap-2.5 text-sm leading-[18px] text-foreground">
                    <Grip className="text-foreground" />
                    <span>Suelta para mover <Mono>{moving}</Mono> {describe(current[code], moving, code)}</span>
                    <span aria-hidden="true" className="text-kbd">·</span>
                    <Kbd>esc</Kbd>
                    <span className="text-muted-foreground">para cancelar</span>
                  </span>
                  <span className="text-xs leading-4 text-muted-foreground">Se ordena dentro de un hito o se lleva a otro. La bandeja de ideas no tiene orden.</span>
                </Notice>
              )}
            </>
          )
        }}
      </Board>
      {pending && <Settle move={pending} reason={reason} onReason={setReason} onSave={() => commit(reason)} onUndo={undo} />}
      {error && !pending && (
        <Notice>
          <span role="alert" className="text-sm leading-[18px] text-foreground">{error}</span>
        </Notice>
      )}
    </>
  )
}

const Mono = ({ children }: { children: ReactNode }) => <span className="font-mono text-control leading-4">{children}</span>

function Grip({ className }: { className?: string }) {
  return (
    <svg aria-hidden="true" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" className={cx("shrink-0", className)}>
      {[6, 12, 18].flatMap((y) => [9, 15].map((x) => <circle key={`${x}-${y}`} cx={x} cy={y} r="1" />))}
    </svg>
  )
}

// El aviso de abajo (Paper): flota centrado sobre la Lista, con borde fino y la sombra de las ventanas.
function Notice({ children, className }: { children: ReactNode; className?: string }) {
  return (
    <div className="pointer-events-none fixed inset-x-0 bottom-6 z-40 flex justify-center px-5 lg:left-[240px]">
      <div className={cx("pointer-events-auto flex flex-col items-center gap-1.5 rounded-xl bg-card px-[18px] py-3 shadow-[0_0_0_1px_var(--color-border),0_12px_40px_color-mix(in_srgb,var(--color-foreground)_16%,transparent)]", className)}>
        {children}
      </div>
    </div>
  )
}

// «Tras soltar (motivo)»: ya está en su sitio; el motivo es opcional y Deshacer la devuelve.
function Settle({ move, reason, onReason, onSave, onUndo }: { move: Move; reason: string; onReason: (reason: string) => void; onSave: () => void; onUndo: () => void }) {
  return (
    <Notice className="w-[680px] max-w-full items-stretch gap-3 px-4 py-3.5">
      <span className="flex items-center justify-between gap-3">
        <span role="status" className="flex items-center gap-2 text-sm leading-[18px] text-foreground">
          <Icon name="check" size={15} strokeWidth={2} />
          <span>{move.sentence}</span>
        </span>
        <button type="button" onClick={onUndo} className="flex items-center gap-1.5 text-control leading-4 text-muted-foreground hover:text-foreground">
          Deshacer<Kbd>⌘Z</Kbd>
        </button>
      </span>
      <form onSubmit={(event) => { event.preventDefault(); onSave() }} className="flex items-center gap-2.5">
        <Input
          autoFocus
          value={reason}
          onValueChange={(value) => onReason(value)}
          onKeyDown={(event) => { if (event.key === "Escape") onSave() }}
          aria-label="Por qué"
          placeholder="¿Por qué? Opcional"
          className="min-w-0 flex-1 rounded-lg bg-card px-3 py-2 text-sm leading-[18px] text-foreground shadow-[0_0_0_1.5px_var(--color-ring)] outline-none placeholder:text-kbd focus-visible:shadow-[0_0_0_1.5px_var(--color-ring)]"
        />
        <Button type="submit" className="h-[34px] rounded-[7px]">
          Guardar<span aria-hidden="true" className="font-mono text-[10px] leading-3 text-kbd">↵</span>
        </Button>
      </form>
      <span className="flex items-center justify-between gap-3 text-xs leading-4 text-muted-foreground">
        <span>Sin motivo también vale: se cierra solo en unos segundos.</span>
        <code className="shrink-0 font-mono text-label leading-[14px] whitespace-pre">{move.command}</code>
      </span>
    </Notice>
  )
}

// Fila que se arrastra (Paper): el asa a la izquierda; al cogerla, deja una raya donde caerá y una copia flotante.
// Sigue siendo un enlace a la historia; Espacio la coge para moverla con el teclado (flechas, y Izquierda/Derecha de hito).
function SortableRow({ item, first, moved, dropped }: { item: Item; first: boolean; moved: boolean; dropped: { current: number } }) {
  return (
    <BoardCard
      value={item.ref}
      render={<Link href={item.url} draggable={false} />}
      onClickCapture={(event: React.MouseEvent) => { if (Date.now() - dropped.current < 400) event.preventDefault() }}
      className={cx(
        "group/row relative grid cursor-grab grid-cols-[16px_52px_1fr_auto] items-center gap-3 py-[13px] hover:bg-card/60",
        !first && "border-t border-border",
        moved && "rounded-md bg-muted hover:bg-muted",
        "data-grabbed:not-data-dragging:rounded-md data-grabbed:not-data-dragging:outline-1 data-grabbed:not-data-dragging:outline-foreground",
        "data-dragging:*:invisible data-dragging:before:absolute data-dragging:before:inset-x-0 data-dragging:before:-top-px data-dragging:before:h-0.5 data-dragging:before:bg-foreground data-dragging:after:absolute data-dragging:after:-top-[3.5px] data-dragging:after:-left-1.5 data-dragging:after:size-[7px] data-dragging:after:rounded-full data-dragging:after:bg-background data-dragging:after:shadow-[inset_0_0_0_2px_var(--color-foreground)]",
        // La copia flotante lleva en línea los estilos calculados de la fila: lo suyo va con «!».
        "data-drag-preview:-ml-2! data-drag-preview:rotate-[0.8deg] data-drag-preview:rounded-[10px]! data-drag-preview:border-0! data-drag-preview:bg-card! data-drag-preview:pr-3.5! data-drag-preview:pl-2! data-drag-preview:shadow-[0_0_0_1px_var(--color-border),0_10px_28px_color-mix(in_srgb,var(--color-foreground)_12%,transparent)]",
      )}
    >
      <Grip className="text-kbd group-data-drag-preview/row:text-foreground" />
      <RowBody item={item} />
    </BoardCard>
  )
}

// Por qué espera, o quién la está construyendo (marca discreta: sigue en la Lista).
function Waiting({ item }: { item: Item }) {
  return waitingParts(item).map((part, index) => (
    <span key={index} className="inline-flex items-center">
      <span className="mr-1 lg:hidden">·</span>
      {part}
    </span>
  ))
}

function waitingParts(item: Item) {
  const parts: ReactNode[] = []
  if (item.building) {
    parts.push(
      <span key="building" className="inline-flex items-center gap-1">
        {item.building.agent && <Icon name="robot" size={12} />}
        en construcción · {item.building.actor}
      </span>,
    )
  }
  if (item.waiting?.kind === "you") {
    parts.push(<span key="you"><span aria-hidden="true" className="text-signal">●</span> te toca a ti</span>)
  } else if (item.waiting?.kind === "stories") {
    const refs = item.waiting.refs
    parts.push(<span key="stories">espera a {refs.length === 1 ? refs[0] : `${refs.length} historias`}</span>)
  }
  return parts
}

// «Apuntar una idea» (N · «v1 · 11»): el título y, si hace falta, una línea más; cae en la bandeja, sin hito.
// En escritorio, ventana arriba; en móvil, hoja inferior.
function NewIdea({ open, onOpenChange, url }: { open: boolean; onOpenChange: (open: boolean) => void; url: string }) {
  const [title, setTitle] = useState("")
  const [body, setBody] = useState("")
  const [sending, setSending] = useState(false)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    if (open) return
    setTitle("")
    setBody("")
    setError(null)
  }, [open])

  const submit = () => {
    if (title.trim() === "" || sending) return
    router.post(url, { title, body }, {
      preserveScroll: true,
      onStart: () => { setSending(true); setError(null) },
      onFinish: () => setSending(false),
      onError: (errors) => setError(Object.values(errors).flat().join(" ")),
      onSuccess: () => onOpenChange(false),
    })
  }
  const short = title.trim().length > 24 ? `${title.trim().slice(0, 24)}…` : title.trim() || "…"

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogBackdrop className="fixed inset-0 z-40 bg-overlay transition-opacity data-starting-style:opacity-0 data-ending-style:opacity-0" />
      <DialogContent className="fixed inset-x-0 bottom-0 z-50 flex flex-col overflow-hidden rounded-t-[18px] bg-card text-foreground shadow-[0_0_0_1px_var(--color-border),0_12px_40px_rgba(17,17,19,0.16)] transition data-starting-style:translate-y-4 data-starting-style:opacity-0 data-ending-style:opacity-0 md:inset-x-auto md:top-[160px] md:bottom-auto md:left-1/2 md:w-[600px] md:-translate-x-1/2 md:rounded-xl md:data-starting-style:translate-y-0">
        <form onSubmit={(event) => { event.preventDefault(); submit() }} className="flex flex-col">
          <span aria-hidden="true" className="mx-auto mt-2 h-1 w-9 rounded-full bg-border md:hidden" />
          <div className="flex items-center justify-between px-5 pt-4">
            <div className="flex items-center gap-2">
              <Icon name="spark" size={14} className="hidden text-muted-foreground md:block" />
              <DialogTitle className="contents"><Eyebrow className="leading-[14px] tracking-[0.1em]">Apuntar una idea</Eyebrow></DialogTitle>
              <Kbd className="max-md:hidden">N</Kbd>
            </div>
            <Kbd className="max-md:hidden">Esc</Kbd>
            <DialogClose className="text-sm text-muted-foreground hover:text-foreground md:hidden">Cancelar</DialogClose>
          </div>
          <DialogDescription className="sr-only">Cae en la Bandeja de ideas, sin hito.</DialogDescription>
          <div className="flex flex-col gap-2 px-5 pt-3.5 pb-[22px]">
            {error && <p role="alert" className="rounded-lg border border-signal/40 px-3 py-2 text-control text-foreground">{error}</p>}
            <Textarea autoFocus autoResize rows={1} value={title} onValueChange={(value) => setTitle(value)} onKeyDown={(event) => { if (event.key === "Enter" && !event.shiftKey && !event.nativeEvent.isComposing) { event.preventDefault(); submit() } }} aria-label="La idea" placeholder="La idea, en una frase" className="resize-none bg-transparent text-[17px] leading-[25px] text-foreground outline-none placeholder:text-kbd focus-visible:shadow-none md:text-lg md:leading-[26px]" />
            <Input value={body} onValueChange={(value) => setBody(value)} aria-label="Una línea más" placeholder="Una línea más, si hace falta" className="bg-transparent text-sm leading-[21px] text-foreground outline-none placeholder:text-kbd focus-visible:shadow-none" />
          </div>
          <div className="mx-5 flex flex-col gap-4 border-t border-border pt-3.5 pb-6 md:mx-0 md:flex-row md:items-center md:justify-between md:gap-4 md:pt-3 md:pr-3.5 md:pb-3 md:pl-5">
            <div className="flex flex-col gap-0.5">
              <span className="flex items-center gap-2 text-control leading-4 text-muted-foreground">
                <Icon name="spark" size={13} className="md:hidden" />Cae en la Bandeja de ideas, sin hito
              </span>
              <code className="hidden font-mono text-label leading-4 text-muted-foreground md:block">mt create "{short}"</code>
            </div>
            <Button type="submit" disabled={sending || title.trim() === ""} className="h-12 justify-center rounded-[10px] text-base md:h-[34px] md:rounded-[7px] md:text-sm">
              Apuntar<span aria-hidden="true" className="font-mono text-[10px] leading-3 text-kbd max-md:hidden">↵</span>
            </Button>
          </div>
        </form>
      </DialogContent>
    </Dialog>
  )
}
