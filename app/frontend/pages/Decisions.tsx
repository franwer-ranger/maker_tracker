import { Link, router, usePage } from "@inertiajs/react"
import { Command, CommandEmpty, CommandInput, CommandItem, CommandItemText, CommandList } from "@ui-sdk/react/command"
import { Dialog, DialogBackdrop, DialogContent, DialogDescription, DialogTitle } from "@ui-sdk/react/dialog"
import { Input } from "@ui-sdk/react/input"
import { Popover, PopoverContent, PopoverTitle, PopoverTrigger } from "@ui-sdk/react/popover"
import { useShortcut } from "@ui-sdk/react/shortcuts"
import { type ReactNode, useEffect, useMemo, useRef, useState } from "react"
import { Button } from "@/components/ui/button"
import { CopyForAgent } from "@/components/ui/copy-for-agent"
import { cx } from "@/components/ui/cx"
import { PresenceOutline } from "@/components/ui/presence"
import { EmptyState } from "@/components/ui/empty-state"
import { Eyebrow } from "@/components/ui/eyebrow"
import { TextField } from "@/components/ui/field"
import { Icon, iconFor } from "@/components/ui/icons"
import { InlineMarkdown } from "@/components/ui/inline-markdown"
import { Kbd } from "@/components/ui/kbd"
import { PageHeader } from "@/components/ui/page-header"
import { SideDecision } from "@/components/ui/side-column"
import { AppShell } from "@/layouts/app-shell"

type Block =
  | { type: "paragraph" | "heading" | "code"; text: string }
  | { type: "list" | "ordered"; items: string[] }

type Item = {
  number: number
  reference: string
  title: string
  why: string | null
  actor: string
  agent: boolean
  at: string
  capabilities: string[]
  superseded_by: string | null
  url: string
}

type Capability = { slug: string; title: string; icon: string | null }
type DecisionLink = { reference: string; title: string; url: string }

type ListProps = {
  items: Item[]
  capabilities: Capability[]
  in_force: number
  superseded: number
  create_url: string
  copy: string
}

type Detail = {
  number: number
  reference: string
  title: string
  why: Block[]
  actor: string
  agent: boolean
  at: string
  capabilities: { title: string; icon: string | null; url: string }[]
  stories: { ref: string; title: string; url: string }[]
  related: DecisionLink[]
  supersedes: DecisionLink | null
  superseded_by: DecisionLink | null
  copy: string
}

const ALL = "__all"
const NONE = "__none"
// Grupos visibles de entrada y filas por grupo: con más de MAX, se ven FOLDED y «+ N más».
const GROUPS = 3
const MAX = 4
const FOLDED = 3

const day = new Intl.DateTimeFormat("es", { day: "numeric", month: "short" })
const shortDate = (iso: string) => day.format(new Date(iso)).replace(".", "")
const normalize = (text: string) => text.normalize("NFD").replace(/[̀-ͯ]/g, "").toLowerCase()

// Las decisiones del producto (MT-105 · «v1 · 7 · Decisiones»): agrupadas por capacidad, buscador (/) y combo
// de capacidad; sustituidas plegadas. La elegida, al lado (en móvil, su propia página). Sin botón en tinta.
export default function Decisions({ decisions, selected }: { decisions: ListProps; selected: Detail | null }) {
  const { project, nav } = usePage().props
  const [creating, setCreating] = useState(false)
  useShortcut("d", () => setCreating(true), { description: "Nueva decisión" })

  const crumbs = selected ? [{ label: "Decisiones", href: nav.decisions }, { label: selected.reference }] : [{ label: "Decisiones" }]
  const actions = (
    <>
      <CopyForAgent text={selected?.copy ?? decisions.copy} shortcut="mod+shift+c" />
      <button type="button" onClick={() => setCreating(true)} className="inline-flex h-8 items-center gap-[7px] rounded-md px-2 text-control text-muted-foreground hover:text-foreground">
        <Icon name="pencil" size={14} />Nueva decisión<Kbd className="hidden md:inline-flex">D</Kbd>
      </button>
    </>
  )
  const dialog = <NewDecision open={creating} onOpenChange={setCreating} decisions={decisions} />

  if (decisions.items.length === 0) {
    return (
      <AppShell title={`Decisiones · ${project.name}`} active="decisions" crumbs={crumbs} copy={decisions.copy} actions={actions}>
        <div className="flex flex-1 items-center justify-center px-5 py-11">
          <EmptyState
            figure="fork"
            title="Ninguna decisión apuntada"
            actions={<Button variant="secondary" onClick={() => setCreating(true)}>Nueva decisión</Button>}
            command="mt decide «…» --why «…»"
          >
            Cuando decidas algo que no se debe olvidar, apúntalo con su porqué. Así no se vuelve a discutir.
          </EmptyState>
        </div>
        {dialog}
      </AppShell>
    )
  }

  return (
    <AppShell title={`${selected ? `${selected.reference} · ` : ""}Decisiones · ${project.name}`} active="decisions" crumbs={crumbs} copy={decisions.copy} actions={actions}>
      <div className="flex flex-col gap-10 px-5 pt-7 pb-10 lg:flex-row lg:items-start lg:gap-12 lg:pt-11 lg:pr-12 lg:pb-14 lg:pl-[72px]">
        <div className={cx("min-w-0 flex-col gap-[30px] lg:flex lg:w-[720px] lg:shrink", selected ? "hidden" : "flex")}>
          <List decisions={decisions} selected={selected?.number ?? null} />
        </div>
        {selected && (
          <aside aria-label={`Decisión ${selected.reference}`} className="flex flex-col gap-4 lg:sticky lg:top-6 lg:w-[330px] lg:shrink-0">
            <Link href={nav.decisions} preserveScroll className="inline-flex items-center gap-1.5 self-start text-control text-muted-foreground hover:text-foreground lg:hidden">
              <Icon name="chevronRight" size={12} className="rotate-180" />Decisiones
            </Link>
            <DetailCard decision={selected} />
          </aside>
        )}
      </div>
      {dialog}
    </AppShell>
  )
}

function List({ decisions, selected }: { decisions: ListProps; selected: number | null }) {
  const { project } = usePage().props
  const [query, setQuery] = useState("")
  const [capability, setCapability] = useState(ALL)
  const [allGroups, setAllGroups] = useState(false)
  const [showSuperseded, setShowSuperseded] = useState(false)
  const search = useRef<HTMLInputElement>(null)
  useShortcut("/", () => search.current?.focus(), { description: "Buscar en las decisiones" })

  const matches = useMemo(() => {
    const words = normalize(query).split(/\s+/).filter(Boolean)
    return decisions.items.filter((item) => {
      if (capability === NONE && item.capabilities.length > 0) return false
      if (capability !== ALL && capability !== NONE && !item.capabilities.includes(capability)) return false
      const haystack = normalize(`${item.reference} ${item.title} ${item.why ?? ""}`)
      return words.every((word) => haystack.includes(word))
    })
  }, [decisions.items, query, capability])

  const inForce = matches.filter((item) => !item.superseded_by)
  const superseded = matches.filter((item) => item.superseded_by)
  const groups = [
    ...decisions.capabilities.map((cap) => ({ key: cap.slug, title: cap.title, icon: cap.icon, items: inForce.filter((item) => item.capabilities.includes(cap.slug)) })),
    { key: NONE, title: "Sin capacidad", icon: null, items: inForce.filter((item) => item.capabilities.length === 0) },
  ].filter((group) => group.items.length > 0 && (capability === ALL || capability === group.key || capability === NONE))
  const filtering = query.trim() !== "" || capability !== ALL
  const visible = allGroups || filtering ? groups : groups.slice(0, GROUPS)
  const hidden = groups.slice(visible.length)
  const options = [{ value: ALL, label: "Todas las capacidades" }, ...decisions.capabilities.map((cap) => ({ value: cap.slug, label: cap.title })), { value: NONE, label: "Sin capacidad" }]

  return (
    <>
      <PageHeader
        eyebrow={`${decisions.in_force} vigentes · ${decisions.superseded} sustituidas`}
        title="Decisiones"
        lead={<>Lo que ya está decidido en {project.name} y por qué.<span className="hidden sm:inline"> Antes de cambiar algo, mira aquí.</span></>}
      />

      <div className="flex flex-col gap-2.5 sm:flex-row sm:items-center">
        <label className="flex flex-1 items-center gap-2 rounded-lg border border-border bg-card px-3 py-2 text-muted-foreground focus-within:border-ring">
          <Icon name="search" size={14} />
          <Input ref={search} value={query} onValueChange={(value) => setQuery(value)} aria-label="Buscar en las decisiones" placeholder="Buscar en las decisiones…" className="min-w-0 flex-1 bg-transparent text-sm leading-[18px] text-foreground outline-none placeholder:text-muted-foreground focus-visible:shadow-none" />
          <Kbd className="hidden sm:inline-flex">/</Kbd>
        </label>
        <Combo label="Capacidad" value={capability} options={options} onChange={setCapability} />
      </div>

      {visible.length === 0 && superseded.length === 0 ? (
        <EmptyState
          figure="search"
          title={query.trim() ? `Ninguna decisión con «${query.trim()}»` : "Ninguna decisión aquí"}
          actions={<Button variant="secondary" onClick={() => { setQuery(""); setCapability(ALL) }}>Quitar el filtro</Button>}
        >
          Quita el filtro para verlas todas.
        </EmptyState>
      ) : (
        visible.map((group) => <Group key={group.key} group={group} selected={selected} open={filtering} />)
      )}

      {hidden.length > 0 && (
        <button type="button" onClick={() => setAllGroups(true)} className="flex items-center justify-between gap-4 border-t border-border py-3.5 text-left text-sm text-muted-foreground hover:text-foreground">
          <span>{hiddenLabel(hidden)}</span>
          <span className="text-control">Mostrar</span>
        </button>
      )}

      {superseded.length > 0 && (
        <section className="flex flex-col">
          <button type="button" aria-expanded={showSuperseded} onClick={() => setShowSuperseded((value) => !value)} className="flex items-center gap-2.5 border-t border-border py-3.5 text-left text-sm text-muted-foreground hover:text-foreground">
            <Icon name="chevronRight" size={12} className={cx("transition-transform", showSuperseded && "rotate-90")} />
            Sustituidas <span className="font-mono text-label">{superseded.length}</span>
          </button>
          {showSuperseded && superseded.map((item) => <Row key={item.number} item={item} selected={item.number === selected} />)}
        </section>
      )}
    </>
  )
}

// «Otras 9 capacidades · y las decisiones sin capacidad».
function hiddenLabel(hidden: { key: string }[]) {
  const others = hidden.filter((group) => group.key !== NONE).length
  const none = hidden.some((group) => group.key === NONE)
  const capabilities = others > 0 ? `Otras ${others} ${others === 1 ? "capacidad" : "capacidades"}` : ""
  if (!none) return capabilities
  return capabilities ? `${capabilities} · y las decisiones sin capacidad` : "Las decisiones sin capacidad"
}

function Group({ group, selected, open }: { group: { key: string; title: string; icon: string | null; items: Item[] }; selected: number | null; open: boolean }) {
  const [expanded, setExpanded] = useState(false)
  const all = open || expanded || group.items.length <= MAX
  const shown = all ? group.items : group.items.slice(0, FOLDED)
  return (
    <section className="flex flex-col">
      <h2 className="flex items-center gap-2.5 pb-2.5">
        <span className="flex size-[26px] shrink-0 items-center justify-center rounded-md bg-muted text-foreground">
          <Icon name={group.key === NONE ? "decision" : iconFor(group.icon)} size={13} />
        </span>
        <span className="text-base leading-5 font-medium text-foreground">{group.title}</span>
        <span className="font-mono text-label text-muted-foreground">{group.items.length}</span>
      </h2>
      {shown.map((item) => <Row key={item.number} item={item} selected={item.number === selected} />)}
      {!all && (
        <button type="button" onClick={() => setExpanded(true)} className="self-start pt-2.5 text-control text-muted-foreground hover:text-foreground lg:pl-16">
          + {group.items.length - FOLDED} más
        </button>
      )}
    </section>
  )
}

// Fila (08): código en mono, la decisión, el porqué en gris, quién (robot si es agente) y cuándo.
function Row({ item, selected }: { item: Item; selected: boolean }) {
  return (
    <Link
      href={item.url}
      preserveScroll
      preserveState
      aria-current={selected ? "true" : undefined}
      className={cx(
        "-mx-3 grid grid-cols-[1fr_auto] gap-x-3.5 gap-y-1.5 rounded-[9px] px-3 py-3.5 lg:grid-cols-[52px_1fr_auto]",
        selected ? "bg-card shadow-[0_0_0_1px_var(--color-border)]" : "border-t border-border hover:bg-card/60",
      )}
    >
      <span className="font-mono text-xs leading-[21px] text-foreground">{item.reference}</span>
      <Who actor={item.actor} agent={item.agent} at={item.at} className="justify-self-end lg:order-last" />
      <span className="col-span-2 flex min-w-0 flex-col gap-1 lg:col-span-1">
        <span className={cx("text-[15px] leading-[21px]", item.superseded_by ? "text-muted-foreground line-through decoration-border" : "text-foreground")}>{item.title}</span>
        {item.superseded_by ? (
          <span className="text-control leading-[19px] text-muted-foreground">sustituida por <span className="font-mono text-label">{item.superseded_by}</span></span>
        ) : (
          item.why && <span className="line-clamp-2 text-control leading-[19px] text-muted-foreground">{item.why.split(/\n\s*\n/)[0]}</span>
        )}
      </span>
    </Link>
  )
}

function Who({ actor, agent, at, className }: { actor: string; agent: boolean; at: string; className?: string }) {
  return (
    <span className={cx("flex items-center gap-1.5 self-start font-mono text-label leading-[21px] whitespace-pre text-muted-foreground", className)}>
      {agent && <Icon name="robot" size={12} />}
      {actor} · {shortDate(at)}
    </span>
  )
}

// El detalle (columna lateral): la decisión, por qué, quién la aplica, relacionadas y su línea de sustituciones.
function DetailCard({ decision }: { decision: Detail }) {
  return (
    <PresenceOutline as="article" target={`decision:${decision.number}`} className="flex flex-col gap-[26px] rounded-xl border border-border bg-card px-6 py-[22px]">
      <div className="flex flex-col gap-2.5">
        <div className="flex items-center justify-between gap-3">
          <span className="font-mono text-xs leading-4 text-foreground">{decision.reference}</span>
          <Who actor={decision.actor} agent={decision.agent} at={decision.at} className="leading-[14px]" />
        </div>
        <h1 className="text-lg leading-[25px] font-medium text-foreground">{decision.title}</h1>
      </div>

      {decision.why.length > 0 && (
        <Side title="Por qué">
          <Prose blocks={decision.why} />
        </Side>
      )}

      {(decision.capabilities.length > 0 || decision.stories.length > 0) && (
        <Side title="La aplican">
          <div className="flex flex-col gap-2">
            {decision.capabilities.map((cap) => (
              <Link key={cap.url} href={cap.url} className="flex items-center gap-2.5 text-control text-foreground hover:underline hover:underline-offset-2">
                <span className="flex size-[26px] shrink-0 items-center justify-center rounded-md bg-muted"><Icon name={iconFor(cap.icon)} size={13} /></span>
                {cap.title}
              </Link>
            ))}
            {decision.stories.length > 0 && (
              <p className="text-control text-muted-foreground">
                {decision.stories.map((story, index) => (
                  <span key={story.ref}>
                    {index > 0 && " · "}
                    <Link href={story.url} title={story.title} className="font-mono text-label leading-[14px] hover:text-foreground">{story.ref}</Link>
                  </span>
                ))}
                {` · ${decision.stories.length} ${decision.stories.length === 1 ? "historia" : "historias"}`}
              </p>
            )}
          </div>
        </Side>
      )}

      {decision.superseded_by && (
        <Side title="Sustituida por">
          <div className="flex flex-col"><SideDecision reference={decision.superseded_by.reference} title={decision.superseded_by.title} href={decision.superseded_by.url} /></div>
        </Side>
      )}
      {decision.supersedes && (
        <Side title="Sustituye a">
          <div className="flex flex-col"><SideDecision reference={decision.supersedes.reference} title={decision.supersedes.title} href={decision.supersedes.url} /></div>
        </Side>
      )}
      {decision.related.length > 0 && (
        <Side title="Relacionadas">
          <div className="flex flex-col">
            {decision.related.map((item) => <SideDecision key={item.reference} reference={item.reference} title={item.title} href={item.url} />)}
          </div>
        </Side>
      )}

      <div className="-mx-2 flex items-center">
        <CopyForAgent text={decision.copy} />
      </div>
    </PresenceOutline>
  )
}

function Side({ title, children }: { title: string; children: ReactNode }) {
  return (
    <section className="flex flex-col gap-2.5">
      <h2 className="contents"><Eyebrow className="leading-[14px] tracking-[0.1em]">{title}</Eyebrow></h2>
      {children}
    </section>
  )
}

// El porqué tal cual, con las piezas de texto de siempre.
function Prose({ blocks }: { blocks: Block[] }) {
  return (
    <div className="flex flex-col gap-2.5 text-sm leading-[21px] text-body">
      {blocks.map((block, index) => {
        switch (block.type) {
          case "heading":
            return <h3 key={index} className="pt-1 text-sm font-medium text-foreground"><InlineMarkdown text={block.text} /></h3>
          case "code":
            return <pre key={index} className="overflow-x-auto rounded-md border border-border bg-background p-3 font-mono text-control text-foreground">{block.text}</pre>
          case "list":
          case "ordered": {
            const List = block.type === "ordered" ? "ol" : "ul"
            return (
              <List key={index} className={cx("flex flex-col gap-1 pl-5", block.type === "ordered" ? "list-decimal" : "list-disc")}>
                {block.items.map((item, position) => <li key={position}><InlineMarkdown text={item} /></li>)}
              </List>
            )
          }
          default:
            return <p key={index}><InlineMarkdown text={block.text} /></p>
        }
      })}
    </div>
  )
}

// Combo (08): Popover + Command de UI SDK, como el de producto, con buscador para muchas opciones.
function Combo({ label, value, options, onChange, className }: { label: string; value: string; options: { value: string; label: string }[]; onChange: (value: string) => void; className?: string }) {
  const [open, setOpen] = useState(false)
  const current = options.find((option) => option.value === value) ?? options[0]
  return (
    <Popover open={open} onOpenChange={setOpen}>
      <PopoverTrigger aria-label={`${label}: ${current.label}`} className={cx("flex items-center justify-between gap-2 rounded-lg border border-border bg-card py-2 pr-2.5 pl-3 text-sm leading-[18px] text-foreground hover:bg-muted", className)}>
        <span className="truncate">{current.label}</span>
        <Icon name="chevronDown" size={12} strokeWidth={2} className="text-muted-foreground" />
      </PopoverTrigger>
      <PopoverContent side="bottom" align="start" sideOffset={6} className="z-50 w-[280px] overflow-hidden rounded-xl border border-border bg-card text-foreground shadow-[0_12px_32px_rgba(15,15,17,0.14)]">
        <PopoverTitle className="sr-only">{label}</PopoverTitle>
        <Command onAction={(next) => { onChange(next); setOpen(false) }} className="flex flex-col">
          <div className="flex h-11 items-center gap-2.5 border-b border-border px-3 text-muted-foreground">
            <Icon name="search" size={14} />
            <CommandInput aria-label={`Buscar ${label.toLowerCase()}`} placeholder="Buscar…" className="h-full flex-1 bg-transparent text-sm text-foreground outline-none placeholder:text-muted-foreground focus-visible:shadow-none" />
          </div>
          <CommandEmpty className="px-3 py-4 text-control text-muted-foreground not-data-empty:hidden">{(state) => `Nada con «${state.query}».`}</CommandEmpty>
          <CommandList className="max-h-72 overflow-y-auto">
            {options.map((option) => (
              <CommandItem key={option.value} value={option.value} label={option.label} className="flex h-10 cursor-default items-center gap-2.5 px-3 text-sm data-highlighted:bg-muted">
                <CommandItemText className="min-w-0 flex-1 truncate [&_mark]:bg-transparent [&_mark]:font-semibold [&_mark]:text-foreground">{option.label}</CommandItemText>
                {option.value === value && <Icon name="check" size={13} className="text-muted-foreground" />}
              </CommandItem>
            ))}
          </CommandList>
        </Command>
      </PopoverContent>
    </Popover>
  )
}

// «Nueva decisión» (acción ligera): la decisión, su porqué, la capacidad que rige y, si cambia otra, cuál.
function NewDecision({ open, onOpenChange, decisions }: { open: boolean; onOpenChange: (open: boolean) => void; decisions: ListProps }) {
  const [title, setTitle] = useState("")
  const [why, setWhy] = useState("")
  const [capability, setCapability] = useState(NONE)
  const [supersedes, setSupersedes] = useState(ALL)
  const [sending, setSending] = useState(false)
  // Lo que el servidor rechaza (ya sustituida, no existe…) vuelve como `errors.base`: el diálogo sigue abierto con lo escrito.
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    if (open) return
    setTitle("")
    setWhy("")
    setCapability(NONE)
    setSupersedes(ALL)
    setError(null)
  }, [open])

  const submit = () => {
    router.post(
      decisions.create_url,
      { title, why, capabilities: capability === NONE ? [] : [capability], supersedes: supersedes === ALL ? "" : supersedes },
      {
        preserveScroll: true,
        onStart: () => { setSending(true); setError(null) },
        onFinish: () => setSending(false),
        onError: (errors) => setError(Object.values(errors).flat().join(" ")),
        onSuccess: () => onOpenChange(false),
      },
    )
  }
  const capabilityOptions = [{ value: NONE, label: "Sin capacidad" }, ...decisions.capabilities.map((cap) => ({ value: cap.slug, label: cap.title }))]
  const supersedeOptions = [
    { value: ALL, label: "No sustituye a ninguna" },
    // La elegida se queda aunque otra pantalla la acabe de sustituir: así el combo no miente al volver el rechazo.
    ...decisions.items.filter((item) => !item.superseded_by || String(item.number) === supersedes).map((item) => ({ value: String(item.number), label: `${item.reference} · ${item.title}` })),
  ]

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogBackdrop className="fixed inset-0 z-40 bg-overlay transition-opacity data-starting-style:opacity-0 data-ending-style:opacity-0" />
      <DialogContent className="fixed inset-x-4 top-[10vh] z-50 flex flex-col gap-5 rounded-xl border border-border bg-card p-6 text-foreground shadow-[0_16px_40px_rgba(15,15,17,0.18)] transition data-starting-style:opacity-0 data-ending-style:opacity-0 md:inset-x-auto md:left-1/2 md:w-[520px] md:-translate-x-1/2">
        <div className="flex flex-col gap-1">
          <DialogTitle className="text-lg leading-6 font-medium">Nueva decisión</DialogTitle>
          <DialogDescription className="text-control text-muted-foreground">Las decisiones no se editan: para cambiar una, apunta otra que la sustituya.</DialogDescription>
        </div>
        <form onSubmit={(event) => { event.preventDefault(); submit() }} className="flex flex-col gap-4">
          {error && (
            <p role="alert" className="rounded-lg border border-signal/40 bg-card px-4 py-3 text-control text-foreground shadow-[inset_2px_0_0_var(--signal)]">{error}</p>
          )}
          <TextField label="La decisión" name="title" value={title} onChange={setTitle} />
          <TextField label="Por qué" name="why" value={why} onChange={setWhy} multiline description="Es lo que se lee después: el motivo, no solo el qué." />
          <div className="flex flex-col gap-1.5">
            <span className="text-control font-medium text-foreground">Capacidad que rige</span>
            <Combo label="Capacidad que rige" value={capability} options={capabilityOptions} onChange={setCapability} />
          </div>
          <div className="flex flex-col gap-1.5">
            <span className="text-control font-medium text-foreground">Sustituye a</span>
            <Combo label="Sustituye a" value={supersedes} options={supersedeOptions} onChange={setSupersedes} />
          </div>
          <div className="flex items-center justify-end gap-2 pt-1">
            <Button type="button" variant="ghost" onClick={() => onOpenChange(false)}>Cancelar</Button>
            <Button type="submit" variant="secondary" disabled={sending || title.trim() === ""}>Apuntar</Button>
          </div>
        </form>
      </DialogContent>
    </Dialog>
  )
}
