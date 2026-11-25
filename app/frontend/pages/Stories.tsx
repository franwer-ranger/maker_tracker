import { Link, router, usePage } from "@inertiajs/react"
import { Dialog, DialogBackdrop, DialogClose, DialogContent, DialogDescription, DialogTitle } from "@ui-sdk/react/dialog"
import { Input } from "@ui-sdk/react/input"
import { SegmentedControl, SegmentedControlIndicator, SegmentedControlItem } from "@ui-sdk/react/segmented-control"
import { useShortcut } from "@ui-sdk/react/shortcuts"
import { type ReactNode, useEffect, useMemo, useRef, useState } from "react"
import { Button } from "@/components/ui/button"
import { Combo } from "@/components/ui/combo"
import { CopyForAgent } from "@/components/ui/copy-for-agent"
import { cx } from "@/components/ui/cx"
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
  url: string
}

type Group = { code: string; title: string; closed: boolean; done: number; total: number; items: Item[] }

type ListProps = {
  groups: Group[]
  ideas: Item[]
  capabilities: Capability[]
  open: number
  done: number
  create_url: string
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

// Historias (MT-109 · «v1 · 8 · Historias»): la Lista por hito en el orden del roadmap y la bandeja de ideas al
// final. Buscador (/), Abiertas/Hechas/Todas y combo de capacidad (en móvil, los filtros en combos). «Apuntar una
// idea» (N) la deja en la bandeja. El Tablero (MT-120) y reordenar arrastrando (MT-121) llegan después.
export default function Stories({ stories }: { stories: ListProps }) {
  const { project } = usePage().props
  const [creating, setCreating] = useState(false)
  useShortcut("n", () => setCreating(true), { description: "Apuntar una idea" })

  const actions = (
    <>
      <CopyForAgent text={stories.copy} shortcut="mod+shift+c" />
      <button type="button" onClick={() => setCreating(true)} className="inline-flex h-8 items-center gap-[7px] rounded-md px-2 text-control text-muted-foreground hover:text-foreground">
        <Icon name="pencil" size={14} />Nueva historia<Kbd className="hidden md:inline-flex">N</Kbd>
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
      ) : (
        <div className="flex justify-center px-5 pt-6 pb-8 lg:px-12 lg:pt-[52px] lg:pb-14">
          <div className="flex w-full min-w-0 flex-col gap-[22px] lg:max-w-[860px] lg:gap-7">
            <List stories={stories} onCreate={() => setCreating(true)} />
          </div>
        </div>
      )}
      <NewIdea open={creating} onOpenChange={setCreating} url={stories.create_url} />
    </AppShell>
  )
}

function List({ stories, onCreate }: { stories: ListProps; onCreate: () => void }) {
  const { project } = usePage().props
  const [query, setQuery] = useState("")
  const [status, setStatus] = useState<Status>("open")
  const [capability, setCapability] = useState(ALL)
  const search = useRef<HTMLInputElement>(null)
  useShortcut("/", () => search.current?.focus(), { description: "Buscar historias" })

  const words = useMemo(() => normalize(query).split(/\s+/).filter(Boolean), [query])
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
  const clear = () => { setQuery(""); setCapability(ALL); setStatus("all") }

  return (
    <>
      <PageHeader
        eyebrow={`${project.name} · ${stories.open} ${stories.open === 1 ? "abierta" : "abiertas"} · ${stories.done} ${stories.done === 1 ? "hecha" : "hechas"}`}
        title="Historias"
        lead={<span className="hidden md:inline">En el orden del roadmap. Lo construido se cuenta en el relato; aquí está lo que queda.</span>}
      />

      <div className="flex items-center gap-2 md:gap-2.5">
        <label className="flex min-w-0 flex-1 items-center gap-2 rounded-lg border border-border bg-card px-3 py-[9px] text-muted-foreground focus-within:border-ring md:py-2">
          <Icon name="search" size={14} strokeWidth={1.8} />
          <Input ref={search} value={query} onValueChange={(value) => setQuery(value)} aria-label="Buscar historias" placeholder="Buscar historias…" className="min-w-0 flex-1 bg-transparent text-sm leading-[18px] text-foreground outline-none placeholder:text-muted-foreground focus-visible:shadow-none" />
          <Kbd className="hidden md:inline-flex">/</Kbd>
        </label>
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

      {groups.map((group) => (
        <Section
          key={group.code}
          heading={<><span className="font-mono text-label leading-[14px] text-muted-foreground lg:text-xs lg:leading-4">{group.code}</span><span className="text-base leading-5 font-medium text-foreground lg:text-lg lg:leading-[22px]">{group.title}</span></>}
          meta={`${group.done} de ${group.total}`}
          items={group.shown}
          fold={filtering ? null : MILESTONE}
        />
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

function emptyTitle(query: string, capability: string | undefined) {
  if (query.trim()) return `Ninguna historia con «${query.trim()}»`
  if (capability) return `Ninguna historia cambia «${capability}»`
  return "Ninguna historia aquí"
}

// Un hito (o la bandeja): cabecera con su código y avance, filas y, si se pliega, «+ N más».
function Section({ heading, meta, items, fold, onCreate, empty }: {
  heading: ReactNode
  meta: ReactNode
  items: Item[]
  fold: { desktop: number; mobile: number } | null
  onCreate?: () => void
  empty?: ReactNode
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
      {items.map((item, index) => (
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
  const label = states[item.state]?.label ?? item.state
  return (
    <Link
      href={item.url}
      className={cx(
        "flex flex-col gap-[5px] border-t border-border py-[13px] hover:bg-card/60 lg:grid lg:grid-cols-[60px_1fr_auto] lg:items-center lg:gap-3.5 lg:px-0",
        className,
      )}
    >
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
    </Link>
  )
}

// Por qué espera, o quién la está construyendo (marca discreta: sigue en la Lista).
function Waiting({ item }: { item: Item }) {
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
  return parts.map((part, index) => (
    <span key={index} className="inline-flex items-center">
      <span className="mr-1 lg:hidden">·</span>
      {part}
    </span>
  ))
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
              <Kbd className="hidden md:inline-flex">N</Kbd>
            </div>
            <Kbd className="hidden md:inline-flex">Esc</Kbd>
            <DialogClose className="text-sm text-muted-foreground hover:text-foreground md:hidden">Cancelar</DialogClose>
          </div>
          <DialogDescription className="sr-only">Cae en la Bandeja de ideas, sin hito.</DialogDescription>
          <div className="flex flex-col gap-2 px-5 pt-3.5 pb-[22px]">
            {error && <p role="alert" className="rounded-lg border border-signal/40 px-3 py-2 text-control text-foreground">{error}</p>}
            <Input autoFocus value={title} onValueChange={(value) => setTitle(value)} aria-label="La idea" placeholder="La idea, en una frase" className="bg-transparent text-[17px] leading-[25px] text-foreground outline-none placeholder:text-kbd focus-visible:shadow-none md:text-lg md:leading-[26px]" />
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
              Apuntar<Kbd tone="ink" className="hidden md:inline-flex">↵</Kbd>
            </Button>
          </div>
        </form>
      </DialogContent>
    </Dialog>
  )
}
