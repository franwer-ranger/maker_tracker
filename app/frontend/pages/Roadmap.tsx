import { Link, router, usePage } from "@inertiajs/react"
import { Dialog, DialogBackdrop, DialogContent, DialogDescription, DialogTitle } from "@ui-sdk/react/dialog"
import { Radio, RadioGroup, RadioIndicator } from "@ui-sdk/react/radio"
import { useShortcut } from "@ui-sdk/react/shortcuts"
import { type ReactNode, useEffect, useRef, useState } from "react"
import { Button } from "@/components/ui/button"
import { CopyForAgent } from "@/components/ui/copy-for-agent"
import { cx } from "@/components/ui/cx"
import { PresenceOutline } from "@/components/ui/presence"
import { EmptyState } from "@/components/ui/empty-state"
import { Eyebrow } from "@/components/ui/eyebrow"
import { TextField } from "@/components/ui/field"
import { Icon, iconFor } from "@/components/ui/icons"
import { Kbd } from "@/components/ui/kbd"
import { PageHeader } from "@/components/ui/page-header"
import { Sortable, SortableHandle, SortableItem } from "@/components/ui/sortable"
import { AppShell } from "@/layouts/app-shell"

type Chapter = {
  number: number
  code: string
  title: string
  goal: string | null
  capabilities: { title: string; icon: string | null; url: string }[]
  done: number
  total: number
  next: { ref: string; title: string; url: string } | null
  pending: { number: number; ref: string; title: string; human_state: string }[]
  following: { number: number; code: string; title: string } | null
  close_url: string
}

type Closed = {
  code: string
  title: string
  goal: string | null
  closed_at: string
  stories: { ref: string; title: string; icon: string | null; url: string }[]
}

type RoadmapProps = {
  vision: string | null
  chapters: Chapter[]
  recent: Closed[]
  recent_window: boolean
  shipped: { code: string; title: string; closed_at: string }[]
  ideas: { count: number; url: string }
  reorder_url: string
  create_url: string
  next_number: number
  copy: string
}

// Historias de un hito recién terminado que se ven antes de «+ N más».
const FOLDED = 4

const day = new Intl.DateTimeFormat("es", { day: "numeric", month: "short" })
const shortDate = (iso: string) => day.format(new Date(iso)).replace(".", "")
const plural = (count: number, one: string, many: string) => `${count} ${count === 1 ? one : many}`

// El roadmap como relato (MT-106 · «v1 · 5 · Roadmap»): los hitos abiertos son capítulos que se ordenan
// arrastrando (o con el teclado), lo recién terminado y lo que ya está. Sin botón en tinta en la página.
export default function Roadmap({ roadmap }: { roadmap: RoadmapProps }) {
  const { project, errors } = usePage<{ errors: Record<string, string | string[]> }>().props
  const [creating, setCreating] = useState(false)
  const [closing, setClosing] = useState<Chapter | null>(null)
  useShortcut("h", () => setCreating(true), { description: "Nuevo hito" })

  const actions = (
    <>
      <CopyForAgent text={roadmap.copy} shortcut="mod+shift+c" />
      <button type="button" onClick={() => setCreating(true)} className="inline-flex h-8 items-center gap-[7px] rounded-md px-2 text-control text-muted-foreground hover:text-foreground">
        <Icon name="pencil" size={14} />Nuevo hito<Kbd className="hidden md:inline-flex">H</Kbd>
      </button>
    </>
  )
  const dialogs = (
    <>
      <NewMilestone open={creating} onOpenChange={setCreating} roadmap={roadmap} />
      <CloseMilestone chapter={closing} onClose={() => setClosing(null)} />
    </>
  )
  const problem = !creating && !closing ? [errors?.base ?? []].flat()[0] : undefined
  const empty = roadmap.chapters.length === 0 && roadmap.recent.length === 0

  return (
    <AppShell title={`Roadmap · ${project.name}`} active="roadmap" crumbs={[{ label: "Roadmap" }]} copy={roadmap.copy} actions={actions}>
      {empty ? (
        <div className="flex flex-1 items-center justify-center px-5 py-11">
          <EmptyState
            figure="flag"
            title="Sin hitos todavía"
            actions={<Button shortcut="H" onClick={() => setCreating(true)}>Nuevo hito</Button>}
            command="mt milestone create «…» --goal «…»"
          >
            Un hito es un sitio al que quieres llegar, con las historias que hacen falta. Crea el primero.
          </EmptyState>
        </div>
      ) : (
        <div className="flex justify-center px-5 pt-7 pb-10 md:px-12 lg:pt-[60px] lg:pb-14">
          <div className="flex w-full max-w-[760px] min-w-0 flex-col gap-10">
            <PageHeader
              eyebrow={<><span className="hidden md:inline">Roadmap · </span>{roadmap.chapters.length === 0 ? "Nada por delante" : `${plural(roadmap.chapters.length, "hito", "hitos")} por delante`}</>}
              title={`Hacia dónde va ${project.name}`}
              lead={roadmap.vision && `${roadmap.vision}${/[.!?]$/.test(roadmap.vision) ? "" : "."} Este es el camino, en orden.`}
            />
            {problem && (
              <p role="alert" className="rounded-lg border border-signal/40 bg-card px-4 py-3 text-control text-foreground">{problem}</p>
            )}
            {roadmap.chapters.length > 0 && <Chapters roadmap={roadmap} onClose={setClosing} />}
            {roadmap.recent.length > 0 && <Recent milestones={roadmap.recent} window={roadmap.recent_window} />}
            {roadmap.shipped.length > 0 && <Shipped milestones={roadmap.shipped} />}
            <Footer ideas={roadmap.ideas} sortable={roadmap.chapters.length > 1} />
          </div>
        </div>
      )}
      {dialogs}
    </AppShell>
  )
}

// Los capítulos: arrastrar el asa (o cogerla con Espacio y moverla con las flechas) cambia el orden de los hitos.
function Chapters({ roadmap, onClose }: { roadmap: RoadmapProps; onClose: (chapter: Chapter) => void }) {
  // Mientras va la petición se ve el orden arrastrado; al volver, el que diga el servidor (también tras un rechazo).
  const [moving, setMoving] = useState<string[] | null>(null)
  const order = moving ?? roadmap.chapters.map((chapter) => String(chapter.number))
  const byKey = new Map(roadmap.chapters.map((chapter) => [String(chapter.number), chapter]))

  const reorder = (next: string[]) => {
    // El hito movido es el que, quitado de los dos órdenes, los deja iguales (en un cambio de vecinos vale cualquiera).
    const without = (list: string[], key: string) => list.filter((other) => other !== key).join(",")
    const moved = next.find((key, index) => key !== order[index] && without(next, key) === without(order, key))
    if (!moved) return
    const index = next.indexOf(moved)
    const place = index === 0 ? { before: next[1] } : { after: next[index - 1] }
    setMoving(next)
    router.post(roadmap.reorder_url, { milestone: moved, ...place, seen: order }, { preserveScroll: true, onFinish: () => setMoving(null) })
  }

  return (
    <Sortable value={order} onValueChange={reorder} label={(key: string) => byKey.get(key)?.title} aria-label="Hitos por delante" className="flex flex-col">
      {order.map((key, index) => {
        const chapter = byKey.get(key)
        if (!chapter) return null
        const label = index === 0 ? "Ahora" : index === 1 ? "Siguiente" : "Después"
        return (
          <SortableItem key={key} value={key} className="relative grid grid-cols-1 gap-3 border-t border-border bg-background py-6 data-dragging:z-10 data-dragging:translate-y-(--drag-y) data-dragging:shadow-[0_12px_32px_rgba(15,15,17,0.14)] data-grabbed:rounded-lg data-grabbed:outline-1 data-grabbed:outline-foreground md:grid-cols-[120px_1fr] md:gap-7 md:py-7">
            <ChapterLabel chapter={chapter} label={label} now={index === 0} sortable={order.length > 1} />
            <ChapterBody chapter={chapter} now={index === 0} onClose={() => onClose(chapter)} />
          </SortableItem>
        )
      })}
    </Sortable>
  )
}

function ChapterLabel({ chapter, label, now, sortable }: { chapter: Chapter; label: string; now: boolean; sortable: boolean }) {
  return (
    <div className="flex items-center justify-between gap-2 md:flex-col md:items-start md:justify-start">
      <div className="flex items-center gap-2">
        {now && <span aria-hidden="true" className="size-1.5 rounded-full bg-signal" />}
        <Eyebrow className={cx("leading-[14px] tracking-[0.1em]", now && "text-foreground")}>{label}</Eyebrow>
      </div>
      <div className="flex items-center gap-2">
        <span className="font-mono text-xs text-muted-foreground">{chapter.code}</span>
        {sortable && (
          <SortableHandle
            value={String(chapter.number)}
            aria-label={`Mover ${chapter.code} · ${chapter.title}`}
            title="Arrastra o pulsa Espacio y usa las flechas"
            className="inline-flex size-6 cursor-grab touch-none items-center justify-center rounded-md text-muted-foreground hover:bg-muted hover:text-foreground active:cursor-grabbing aria-pressed:bg-muted aria-pressed:text-foreground"
          >
            <svg aria-hidden="true" width="12" height="12" viewBox="0 0 12 12" fill="currentColor">
              {[2, 6, 10].flatMap((y) => [4, 8].map((x) => <circle key={`${x}-${y}`} cx={x} cy={y} r="1" />))}
            </svg>
          </SortableHandle>
        )}
      </div>
    </div>
  )
}

function ChapterBody({ chapter, now, onClose }: { chapter: Chapter; now: boolean; onClose: () => void }) {
  const complete = chapter.total > 0 && chapter.done === chapter.total
  return (
    <PresenceOutline target={`milestone:${chapter.number}`} className="flex min-w-0 flex-col gap-3">
      <h2 className={cx("font-medium tracking-[-0.015em] text-foreground", now ? "text-[22px] leading-7 md:text-2xl md:leading-[30px]" : "text-lg leading-6 md:text-xl md:leading-[26px]")}>{chapter.title}</h2>
      {chapter.goal && <p className="text-[15px] leading-[23px] text-body">{chapter.goal}</p>}
      {chapter.capabilities.length > 0 && (
        <div className="flex flex-wrap gap-2">
          {chapter.capabilities.map((capability) => (
            <Link key={capability.url} href={capability.url} className="inline-flex items-center gap-1.5 rounded-full border border-border bg-card py-[3px] pr-[9px] pl-[7px] text-xs text-foreground hover:bg-muted">
              <Icon name={iconFor(capability.icon)} size={12} />{capability.title}
            </Link>
          ))}
        </div>
      )}
      <Progress done={chapter.done} total={chapter.total} />
      {complete ? (
        <div className="flex flex-wrap items-center gap-3 rounded-lg border border-border bg-card px-4 py-3">
          <span aria-hidden="true" className="size-1.5 rounded-full bg-signal" />
          <p className="min-w-0 flex-1 text-control text-foreground">Todo hecho: ya se puede cerrar.</p>
          <Button variant="secondary" onClick={onClose}>Cerrar {chapter.code}</Button>
        </div>
      ) : (
        <div className="flex flex-wrap items-baseline justify-between gap-x-4 gap-y-1">
          {chapter.next ? (
            <p className="text-control text-muted-foreground">
              Sigue <Link href={chapter.next.url} className="font-mono text-foreground hover:underline">{chapter.next.ref}</Link> · {chapter.next.title}
            </p>
          ) : (
            <p className="text-control text-muted-foreground">Sin historias todavía.</p>
          )}
          <button type="button" onClick={onClose} className="text-control text-muted-foreground hover:text-foreground">Cerrar</button>
        </div>
      )}
    </PresenceOutline>
  )
}

// Avance en puntos: uno por historia, en tinta las hechas.
function Progress({ done, total }: { done: number; total: number }) {
  if (total === 0) return null
  return (
    <div className="flex items-center gap-3 pt-1">
      <div aria-hidden="true" className="flex flex-wrap gap-1">
        {Array.from({ length: total }, (_, index) => (
          <span key={index} className={cx("size-[7px] shrink-0 rounded-full", index < done ? "bg-foreground" : "bg-border")} />
        ))}
      </div>
      <span className="font-mono text-label leading-[14px] text-muted-foreground">{done} de {total}</span>
    </div>
  )
}

function Recent({ milestones, window }: { milestones: Closed[]; window: boolean }) {
  return (
    <section aria-labelledby="recent" className="flex flex-col gap-10">
      {milestones.map((milestone, index) => (
        <RecentMilestone key={milestone.code} milestone={milestone} heading={index === 0} window={window} />
      ))}
    </section>
  )
}

function RecentMilestone({ milestone, heading, window }: { milestone: Closed; heading: boolean; window: boolean }) {
  const [all, setAll] = useState(false)
  const stories = all ? milestone.stories : milestone.stories.slice(0, FOLDED)
  return (
    <div className="flex flex-col gap-3.5">
      <div className="flex flex-wrap items-baseline justify-between gap-x-4 gap-y-1">
        <h2 id={heading ? "recent" : undefined} className="text-xl leading-6 font-medium tracking-[-0.01em] text-foreground">
          {heading ? "Recién terminado" : milestone.title}
        </h2>
        <span className={cx("shrink-0 font-mono text-muted-foreground", window ? "text-label" : "text-control text-foreground")}>
          {milestone.code} · {window ? "" : "cerrado el "}{shortDate(milestone.closed_at)}
        </span>
      </div>
      {heading && <p className="text-[15px] leading-[23px] text-foreground">{milestone.title}</p>}
      {milestone.goal && <p className="text-[15px] leading-[23px] text-body">{milestone.goal}</p>}
      {stories.length > 0 && (
        <ul className="flex flex-col">
          {stories.map((story) => (
            <li key={story.ref}>
              <Link href={story.url} className="flex items-center gap-3.5 border-t border-border py-2.5 hover:bg-muted/50">
                <span className="flex size-7 shrink-0 items-center justify-center rounded-[7px] bg-muted text-foreground">
                  <Icon name={iconFor(story.icon)} size={14} />
                </span>
                <span className="min-w-0 flex-1 text-sm leading-[18px] text-foreground">{story.title}</span>
                <span className="hidden shrink-0 font-mono text-label text-muted-foreground md:inline">{story.ref}</span>
              </Link>
            </li>
          ))}
        </ul>
      )}
      {!all && milestone.stories.length > FOLDED && (
        <button type="button" onClick={() => setAll(true)} className="self-start text-control text-muted-foreground hover:text-foreground">+ {milestone.stories.length - FOLDED} más</button>
      )}
    </div>
  )
}

function Shipped({ milestones }: { milestones: RoadmapProps["shipped"] }) {
  const [open, setOpen] = useState(false)
  return (
    <section aria-labelledby="shipped" className="flex flex-col">
      <button type="button" onClick={() => setOpen(!open)} aria-expanded={open} className="flex items-center justify-between border-t border-border py-3.5 text-left md:hidden">
        <span className="text-sm text-muted-foreground">Lo que ya está · <span className="font-mono text-foreground">{milestones.length}</span> {milestones.length === 1 ? "hito" : "hitos"}</span>
        <Icon name="chevronRight" size={12} className={cx("text-muted-foreground transition-transform", open && "rotate-90")} />
      </button>
      <div className={cx("flex-col md:flex", open ? "flex" : "hidden")}>
        <div className="hidden items-baseline justify-between pb-2.5 md:flex">
          <h2 id="shipped" className="text-xl leading-6 font-medium tracking-[-0.01em] text-foreground">Lo que ya está</h2>
          <span className="text-control text-muted-foreground">{plural(milestones.length, "hito", "hitos")}</span>
        </div>
        {milestones.map((milestone) => (
          <div key={milestone.code} className="grid grid-cols-[52px_1fr_auto] gap-3.5 border-t border-border py-2.5">
            <span className="font-mono text-label leading-5 text-muted-foreground">{milestone.code}</span>
            <span className="text-sm leading-5 text-foreground">{milestone.title}</span>
            <span className="font-mono text-label leading-5 text-muted-foreground">{shortDate(milestone.closed_at)}</span>
          </div>
        ))}
      </div>
    </section>
  )
}

function Footer({ ideas, sortable }: { ideas: RoadmapProps["ideas"]; sortable: boolean }) {
  return (
    <div className="flex items-center justify-between gap-4 border-t border-border py-3.5">
      <a href={ideas.url} className="flex items-center gap-2.5 text-sm text-muted-foreground hover:text-foreground">
        <Icon name="spark" size={14} />
        <span>Bandeja de ideas · <span className="font-mono text-foreground">{ideas.count}</span> sin hito</span>
      </a>
      {sortable && <span className="hidden text-xs text-muted-foreground md:inline">Arrastra un hito para cambiar el orden</span>}
    </div>
  )
}

const dialogContent = "fixed inset-x-4 top-[8vh] z-50 flex max-h-[84vh] flex-col overflow-y-auto rounded-xl border border-border bg-card text-foreground shadow-[0_16px_40px_rgba(15,15,17,0.18)] transition data-starting-style:opacity-0 data-ending-style:opacity-0 md:inset-x-auto md:left-1/2 md:w-[560px] md:-translate-x-1/2"

function Window({ open, onOpenChange, title, description, command, children, footer }: { open: boolean; onOpenChange: (open: boolean) => void; title: string; description: ReactNode; command: string; children: ReactNode; footer: ReactNode }) {
  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogBackdrop className="fixed inset-0 z-40 bg-overlay transition-opacity data-starting-style:opacity-0 data-ending-style:opacity-0" />
      <DialogContent className={dialogContent}>
        <div className="flex flex-col gap-4 p-6">
          <div className="flex items-center justify-between">
            <Eyebrow>Roadmap</Eyebrow>
            <Kbd className="hidden md:inline-flex">Esc</Kbd>
          </div>
          <div className="flex flex-col gap-1.5">
            <DialogTitle className="text-lg leading-6 font-medium">{title}</DialogTitle>
            <DialogDescription className="text-sm text-muted-foreground">{description}</DialogDescription>
          </div>
          {children}
        </div>
        <div className="flex flex-wrap items-center justify-between gap-3 border-t border-border px-6 py-3">
          <code className="font-mono text-label text-muted-foreground">{command}</code>
          <div className="flex items-center gap-2">{footer}</div>
        </div>
      </DialogContent>
    </Dialog>
  )
}

function Choice({ value, title, hint, aside }: { value: string; title: ReactNode; hint: ReactNode; aside?: ReactNode }) {
  return (
    <Radio value={value} className="flex items-center gap-3 rounded-lg border border-border px-4 py-3 text-left transition-colors hover:bg-muted data-checked:border-foreground data-checked:hover:bg-transparent">
      <span className="flex size-4 shrink-0 items-center justify-center rounded-full border border-muted-foreground">
        <RadioIndicator className="size-2 rounded-full bg-foreground" />
      </span>
      <span className="flex min-w-0 flex-1 flex-col gap-0.5">
        <span className="text-sm text-foreground">{title}</span>
        <span className="text-xs text-muted-foreground">{hint}</span>
      </span>
      {aside && <span className="shrink-0 font-mono text-label text-muted-foreground">{aside}</span>}
    </Radio>
  )
}

// Un envío cada vez, venga del botón, de ⌘↵ o del formulario: el ref para también dos keydown en el mismo tick.
function useSubmit(onSuccess: () => void) {
  const [sending, setSending] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const busy = useRef(false)
  const send = (url: string, data: Record<string, unknown>) => {
    if (busy.current) return
    busy.current = true
    router.post(url, data as never, {
      preserveScroll: true,
      onStart: () => { setSending(true); setError(null) },
      onFinish: () => { busy.current = false; setSending(false) },
      onError: (errors) => setError(Object.values(errors).flat().join(" ")),
      onSuccess,
    })
  }
  return { sending, error, setError, send }
}

function Problem({ error }: { error: string | null }) {
  return error ? <p role="alert" className="rounded-lg border border-signal/40 bg-card px-4 py-3 text-control text-foreground">{error}</p> : null
}

// «Nuevo hito» (acción ligera, H): nombre, objetivo y dónde va en el orden.
function NewMilestone({ open, onOpenChange, roadmap }: { open: boolean; onOpenChange: (open: boolean) => void; roadmap: RoadmapProps }) {
  const [title, setTitle] = useState("")
  const [goal, setGoal] = useState("")
  const [place, setPlace] = useState("end")
  const { sending, error, setError, send } = useSubmit(() => onOpenChange(false))
  const [first, second] = roadmap.chapters
  const last = roadmap.chapters[roadmap.chapters.length - 1]

  useEffect(() => {
    if (open) return
    setTitle("")
    setGoal("")
    setPlace("end")
    setError(null)
  }, [open, setError])

  const submit = () => { if (title.trim() !== "") send(roadmap.create_url, { title, goal, place }) }
  return (
    <Window
      open={open}
      onOpenChange={onOpenChange}
      title="Nuevo hito"
      description="Un paso del roadmap. Las historias se le asignan después, desde cada historia."
      command={"mt milestone create «…» --goal «…»"}
      footer={<>
        <Button variant="ghost" onClick={() => onOpenChange(false)}>Cancelar</Button>
        <Button shortcut="⌘↵" onClick={submit} disabled={sending || title.trim() === ""}>Crear hito</Button>
      </>}
    >
      <form onSubmit={(event) => { event.preventDefault(); submit() }} onKeyDown={(event) => { if (event.key === "Enter" && (event.metaKey || event.ctrlKey)) { event.preventDefault(); submit() } }} className="flex flex-col gap-4">
        <Problem error={error} />
        <TextField label="Nombre" name="title" value={title} onChange={setTitle} />
        <TextField label="Objetivo" name="goal" value={goal} onChange={setGoal} description="Lo que tiene que ser verdad para cerrarlo. Se ve en el roadmap bajo el nombre." />
        {first && (
          <div className="flex flex-col gap-2">
            <span className="text-control font-medium text-foreground">Dónde va en el orden</span>
            <RadioGroup value={place} onValueChange={(next) => next && setPlace(next)} aria-label="Dónde va en el orden" className="flex flex-col gap-2">
              <Choice value="end" title={<>Al final, después de {last?.code} · {last?.title}</>} hint="Lo normal: lo siguiente cuando acabe lo que hay." aside={`será M${roadmap.next_number}`} />
              {second && <Choice value="next" title={<>Entre {first.code} y {second.code}</>} hint="Pasa a ser el siguiente; los demás corren un puesto." />}
              <Choice value="first" title={<>Antes de {first.code} · {first.title}</>} hint="Pasa a ser lo de ahora; los demás corren un puesto." />
            </RadioGroup>
          </div>
        )}
      </form>
    </Window>
  )
}

// «Cerrar un hito»: cuenta lo que queda abierto y deja elegir a dónde va (el siguiente hito o la bandeja).
function CloseMilestone({ chapter, onClose }: { chapter: Chapter | null; onClose: () => void }) {
  const [destination, setDestination] = useState("next")
  const { sending, error, setError, send } = useSubmit(onClose)
  const [shown, setShown] = useState<Chapter | null>(chapter)
  useEffect(() => {
    if (!chapter) return
    setShown(chapter)
    setDestination(chapter.following ? "next" : "ideas")
    setError(null)
  }, [chapter, setError])
  const current = chapter ?? shown
  if (!current) return null

  const pending = current.pending
  const states = [...new Set(pending.map((story) => story.human_state))]
  const submit = () => send(current.close_url, {
    open: pending.map((story) => story.number),
    destination: pending.length > 0 ? destination : "",
    to: current.following?.number ?? "",
  })

  return (
    <Window
      open={chapter !== null}
      onOpenChange={(open) => { if (!open) onClose() }}
      title={`¿Cerrar ${current.code} · ${current.title}?`}
      description={current.done > 0 ? `${current.done === 1 ? "La hecha se queda" : `Las ${current.done} hechas se quedan`} en el hito y en el relato.` : "Pasa a «Lo que ya está» del roadmap."}
      command={`mt milestone close ${current.code}`}
      footer={<>
        <Button variant="ghost" onClick={onClose}>Cancelar</Button>
        <Button shortcut="⌘↵" onClick={submit} disabled={sending}>Cerrar {current.code}</Button>
      </>}
    >
      <div onKeyDown={(event) => { if (event.key === "Enter" && (event.metaKey || event.ctrlKey)) { event.preventDefault(); submit() } }} className="flex flex-col gap-4">
        <Problem error={error} />
        {current.total > 0 && (
          <div className="flex flex-col gap-2">
            <div className="flex items-baseline justify-between gap-3">
              <span className="text-control font-medium text-foreground">
                {pending.length === 0 ? "No queda nada abierto" : `${pending.length === 1 ? "Queda 1 abierta" : `Quedan ${pending.length} abiertas`}${states.length === 1 ? `, ${pending.length === 1 ? "en" : "todas en"} ${states[0]}` : ""}`}
              </span>
              <span className="font-mono text-label tracking-label text-muted-foreground uppercase">{current.done} de {current.total} hechas</span>
            </div>
            <div aria-hidden="true" className="h-1 overflow-hidden rounded-full bg-border">
              <div className="h-full bg-foreground" style={{ width: `${(current.done / current.total) * 100}%` }} />
            </div>
          </div>
        )}
        {pending.length > 0 && (
          <>
            <ul className="flex flex-col">
              {pending.map((story) => (
                <li key={story.ref} className="grid grid-cols-[66px_1fr] gap-2 border-t border-border py-2 text-control">
                  <span className="font-mono text-muted-foreground">{story.ref}</span>
                  <span className="text-foreground">{story.title}</span>
                </li>
              ))}
            </ul>
            <div className="flex flex-col gap-2">
              <span className="text-control font-medium text-foreground">Qué pasa con {pending.length === 1 ? "la abierta" : `las ${pending.length} abiertas`}</span>
              <RadioGroup value={destination} onValueChange={(next) => next && setDestination(next)} aria-label="Qué pasa con las abiertas" className="flex flex-col gap-2">
                {current.following && <Choice value="next" title={<>Pasan a {current.following.code} · {current.following.title}</>} hint="Al principio, en el mismo orden. No cambian de estado." />}
                <Choice value="ideas" title="Van a la bandeja, sin hito" hint="Sin orden hasta que les des un hito. No cambian de estado." />
              </RadioGroup>
            </div>
          </>
        )}
      </div>
    </Window>
  )
}
