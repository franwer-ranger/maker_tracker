import { Link, router, usePage } from "@inertiajs/react"
import { Collapsible, CollapsiblePanel, CollapsibleTrigger } from "@ui-sdk/react/collapsible"
import { Popover, PopoverClose, PopoverContent, PopoverDescription, PopoverTitle, PopoverTrigger } from "@ui-sdk/react/popover"
import { useShortcut } from "@ui-sdk/react/shortcuts"
import { Textarea } from "@ui-sdk/react/textarea"
import { type ReactNode, useState } from "react"
import { Button } from "@/components/ui/button"
import { CopyForAgent } from "@/components/ui/copy-for-agent"
import { cx } from "@/components/ui/cx"
import { Eyebrow } from "@/components/ui/eyebrow"
import { Icon, iconFor } from "@/components/ui/icons"
import { InlineMarkdown } from "@/components/ui/inline-markdown"
import { Kbd } from "@/components/ui/kbd"
import { OpenQuestion } from "@/components/ui/open-question"
import { PageHeader } from "@/components/ui/page-header"
import { SideDecision, SideSection } from "@/components/ui/side-column"
import { StateBadge, type StoryState } from "@/components/ui/state"
import { AppShell } from "@/layouts/app-shell"

type Block =
  | { type: "paragraph" | "heading" | "code"; text: string }
  | { type: "list" | "ordered"; items: string[] }

type Question = {
  id: number
  title: string
  context: string | null
  actor: string
  blocking: boolean
  recommended: number | null
  options: { value: string; label: string }[]
  answer_url: string
}

type StoryProps = {
  ref: string
  number: number
  title: string
  state: StoryState
  milestone: string | null
  building: { agent: string | null; since: string | null } | null
  closed: { at: string | null; commits: string[] } | null
  sentence: string | null
  question: Question | null
  ready_url: string | null
  ready_blockers: string[]
  changes: { capability: string; icon: string | null; adds: string[]; keeps: string[]; url: string }[]
  changes_text: string | null
  documentation:
    | { kind: "unlinked"; prompt: string; candidate: { title: string; icon: string | null; area: string | null; link_url: string } | null }
    | { kind: "outdated"; prompt: string; relink: boolean; pages: { title: string; icon: string | null; url: string }[] }
    | null
  // Las casillas, los subtítulos que las agrupan y el texto suelto de la sección, en orden.
  criteria: ({ type: "check"; text: string; done: boolean } | { type: "heading" | "paragraph"; text: string })[]
  out_of_scope: string[]
  context: { title: string | null; blocks: Block[] }[]
  screens: { code: string; title: string; href: string; src: string | null }[]
  decisions: { reference: string; title: string; superseded: string | null; url: string }[]
  activity: { actor: string; agent: boolean; text: string; at: string }[]
  events: number
  comments: { id: number; actor: string; agent: boolean; at: string; blocks: Block[] }[]
  copy: string
  edit_url: string
  history_url: string
  comment_url: string
}

const day = new Intl.DateTimeFormat("es", { day: "numeric", month: "short" })
const clock = new Intl.DateTimeFormat("es", { hour: "2-digit", minute: "2-digit" })
const shortDate = (iso: string) => day.format(new Date(iso)).replace(".", "")
const time = (iso: string) => clock.format(new Date(iso))

// Una historia (MT-104 · «v1 · 4 · Historia»): se lee como un documento. Un solo botón en tinta:
// «Responder» si hay pregunta abierta, «Marcar como Lista» si está en Definiendo y no le falta nada.
// Sin QA (D-97) ni «En curso»: en curso es Lista con la marca «en construcción». `story` es una live prop.
export default function Story({ story }: { story: StoryProps }) {
  const { project, nav } = usePage().props
  const crumbs = [{ label: "Historias", href: nav.board }, { label: story.ref }]
  const checks = story.criteria.filter((item) => item.type === "check")
  const canMarkReady = !story.question && story.ready_url && story.ready_blockers.length === 0
  const markReady = () => story.ready_url && router.post(story.ready_url, {}, { preserveScroll: true })
  useShortcut(canMarkReady ? "l" : null, markReady, { description: "Marcar como Lista" })

  const actions = (
    <>
      <CopyForAgent text={story.copy} shortcut="mod+shift+c" />
      <Edit story={story} />
    </>
  )

  const side = (
    <>
      <SideSection title="Pantallas" labelledBy="pantallas"><Screens screens={story.screens} /></SideSection>
      {story.decisions.length > 0 && (
        <SideSection title="La rigen" labelledBy="la-rigen">
          {story.decisions.map((decision) => (
            <SideDecision key={decision.reference} reference={decision.superseded ? `${decision.reference} · sustituida por ${decision.superseded}` : decision.reference} title={decision.title} href={decision.url} />
          ))}
        </SideSection>
      )}
      {story.activity.length > 0 && (
        <SideSection title={story.closed ? "Historial" : "Actividad"} labelledBy="actividad">
          <ul className="flex flex-col gap-2">
            {story.activity.map((item, index) => (
              <li key={index} className="flex items-start gap-2 text-xs leading-[18px] text-muted-foreground">
                <span className="mt-0.5 w-3.5 shrink-0">{item.agent && <Icon name="robot" size={13} aria-label="agente" />}</span>
                <span><span className="font-mono text-label text-foreground">{item.actor}</span> {item.text} · {shortDate(item.at)}</span>
              </li>
            ))}
          </ul>
          {story.events > story.activity.length && (
            <a href={story.history_url} className="mt-3 self-start text-control text-foreground underline decoration-border underline-offset-[3px] hover:decoration-foreground">Ver los {story.events} eventos</a>
          )}
        </SideSection>
      )}
    </>
  )

  return (
    <AppShell title={`${story.ref} · ${story.title} · ${project.name}`} active="stories" crumbs={crumbs} copy={story.copy} actions={actions}>
      <div className="flex flex-col gap-10 px-5 pt-7 pb-10 lg:flex-row lg:items-start lg:gap-14 lg:pt-12 lg:pr-14 lg:pb-14 lg:pl-[72px]">
        <article className="flex min-w-0 flex-col gap-10 lg:w-[700px] lg:shrink">
          <PageHeader status={<Status story={story} />} title={story.title} lead={story.sentence && <InlineMarkdown text={story.sentence} />} />

          {story.question ? (
            <OpenQuestion
              question={story.question.title}
              context={story.question.context ?? undefined}
              blocks={story.question.blocking ? "Bloquea pasarla a Lista" : undefined}
              options={story.question.options.map((option) => ({ ...option, recommended: String(story.question!.recommended) === option.value }))}
              onAnswer={(option) => router.post(story.question!.answer_url, { question_id: story.question!.id, option }, { preserveScroll: true })}
            />
          ) : story.ready_url && (
            <ReadyBar blockers={story.ready_blockers} onReady={markReady} />
          )}

          <Changes story={story} />

          {story.criteria.length > 0 && (
            <section aria-labelledby="criterios" className="flex flex-col">
              <div className="flex items-baseline justify-between gap-4 pb-4">
                <h2 id="criterios" className="text-xl leading-6 font-medium tracking-[-0.01em] text-foreground">Criterios de aceptación</h2>
                {checks.length > 0 && <span className="font-mono text-label text-muted-foreground">{checks.filter((item) => item.done).length}/{checks.length}</span>}
              </div>
              <ul className="flex flex-col">
                {story.criteria.map((item, index) =>
                  item.type === "check" ? (
                    <li key={index} className="flex items-start gap-3 border-t border-border py-3.5 text-sm leading-[21px] text-foreground last:pb-0">
                      <span aria-label={item.done ? "cumplido" : "pendiente"} className={cx("mt-0.5 flex size-4 shrink-0 items-center justify-center rounded-sm border", item.done ? "border-foreground text-foreground" : "border-muted-foreground")}>
                        {item.done && <Icon name="check" size={11} strokeWidth={2.4} />}
                      </span>
                      <span><InlineMarkdown text={item.text} /></span>
                    </li>
                  ) : item.type === "heading" ? (
                    <li key={index} className="border-t border-border pt-5 pb-2 text-sm leading-[21px] font-medium text-foreground"><InlineMarkdown text={item.text} /></li>
                  ) : (
                    <li key={index} className="border-t border-border py-3.5 text-sm leading-[21px] whitespace-pre-line text-body last:pb-0"><InlineMarkdown text={item.text} /></li>
                  ),
                )}
              </ul>
            </section>
          )}

          {(story.out_of_scope.length > 0 || story.context.length > 0) && (
            <div className="flex flex-col gap-4 border-t border-border pt-4">
              {story.out_of_scope.length > 0 && (
                <p className="flex flex-col gap-1 text-control leading-5 text-muted-foreground sm:flex-row sm:gap-3">
                  <Eyebrow className="shrink-0 leading-5">Fuera de alcance</Eyebrow>
                  <span>{story.out_of_scope.map((item, index) => <span key={index}>{index > 0 && " · "}<InlineMarkdown text={item} /></span>)}</span>
                </p>
              )}
              {story.context.length > 0 && <Context sections={story.context} />}
            </div>
          )}

          <Comments story={story} />
        </article>

        <aside aria-label="Contexto de la historia" className="flex flex-col gap-[30px] lg:w-[300px] lg:shrink-0 lg:pt-1.5">
          {side}
        </aside>
      </div>
    </AppShell>
  )
}

// Estado e hito; en construcción, quién y desde cuándo (en gris: la vida naranja es del marco); Hecha, fecha y commits.
function Status({ story }: { story: StoryProps }) {
  return (
    <span className="flex flex-wrap items-center gap-x-3 gap-y-1.5 font-mono text-label tracking-[0.06em] text-muted-foreground uppercase">
      <StateBadge state={story.state} className="font-sans tracking-normal normal-case" />
      {story.building && (
        <span className="inline-flex items-center gap-1.5 normal-case">
          <Icon name="robot" size={13} />
          en construcción{story.building.agent && ` · ${story.building.agent}`}{story.building.since && ` · desde ${time(story.building.since)}`}
        </span>
      )}
      {story.closed?.at && (
        <span className="normal-case">
          {shortDate(story.closed.at)} · {time(story.closed.at)}
          {story.closed.commits.length > 0 && <span className="text-foreground">{"  "}{story.closed.commits.join(" · ")}</span>}
        </span>
      )}
      {story.milestone && <span className={cx((story.building || story.closed) && "border-l border-border pl-3")}>{story.milestone}</span>}
    </span>
  )
}

// Sin pregunta abierta, en Definiendo: «Marcar como Lista» es el botón en tinta; si le falta algo, lo dice.
function ReadyBar({ blockers, onReady }: { blockers: string[]; onReady: () => void }) {
  return (
    <section className="flex flex-col gap-3 rounded-xl border border-border bg-card p-5 sm:flex-row sm:items-center sm:justify-between">
      <span className="text-sm text-body">{blockers.length > 0 ? blockers.join(" ") : "No le falta nada: ya se puede construir."}</span>
      <Button shortcut="L" onClick={onReady} disabled={blockers.length > 0} className="self-start sm:self-auto">Marcar como Lista</Button>
    </section>
  )
}

// «Editar» abre el formulario. En construcción avisa antes y propone comentar.
function Edit({ story }: { story: StoryProps }) {
  const goEdit = () => { window.location.href = story.edit_url }
  useShortcut(story.building ? null : "e", goEdit, { description: "Editar" })
  const trigger = "inline-flex h-8 items-center gap-2 rounded-md px-2 text-control text-muted-foreground hover:text-foreground data-open:bg-muted data-open:text-foreground"
  if (!story.building) {
    return <a href={story.edit_url} className={trigger}><Icon name="pencil" size={14} />Editar<Kbd className="border-0 px-0">E</Kbd></a>
  }
  return (
    <Popover>
      <PopoverTrigger className={trigger}><Icon name="pencil" size={14} />Editar<Kbd className="border-0 px-0">E</Kbd></PopoverTrigger>
      <PopoverContent side="bottom" align="end" className="z-50 flex w-[360px] max-w-[calc(100vw-32px)] flex-col gap-2.5 rounded-xl border border-border bg-card p-5 shadow-lg">
        <PopoverTitle className="flex items-center gap-2 text-sm font-medium text-foreground">
          <Icon name="robot" size={14} />
          {story.building.agent ?? "Un agente"} la está construyendo{story.building.since && ` desde las ${time(story.building.since)}`}
        </PopoverTitle>
        <PopoverDescription className="text-control leading-5 text-body">
          Si cambias la definición ahora, no lo verá hasta que termine y lo construido puede no coincidir. Mejor dejarle un comentario, o editarla cuando la cierre.
        </PopoverDescription>
        <div className="flex items-center justify-end gap-2 pt-1">
          <a href={story.edit_url} className="inline-flex h-8 items-center gap-2 rounded-md px-2 text-control text-muted-foreground hover:text-foreground"><Icon name="pencil" size={13} />Editar igualmente</a>
          <PopoverClose
            className="inline-flex h-8 items-center rounded-md border border-border bg-card px-3 text-control text-foreground hover:bg-muted"
            onClick={() => document.getElementById("comentario")?.focus()}
          >
            Dejar un comentario
          </PopoverClose>
        </div>
      </PopoverContent>
    </Popover>
  )
}

function Changes({ story }: { story: StoryProps }) {
  const done = story.state === "done"
  const title = done ? "Qué cambió del producto" : "Qué cambia del producto"
  const doc = story.documentation
  return (
    <section aria-labelledby="cambios" className="flex flex-col">
      <div className="flex items-baseline justify-between gap-4 border-b border-border pb-4">
        <h2 id="cambios" className="text-xl leading-6 font-medium tracking-[-0.01em] text-foreground">{title}</h2>
        {story.changes.length > 0 && !done && <span className="hidden text-control text-muted-foreground sm:inline">Al cerrarla, estas páginas quedan al día</span>}
      </div>

      {doc && <Documentation story={story} doc={doc} />}

      {story.changes.map((block) => (
        <div key={block.url} className="flex gap-4 border-b border-border py-5 last:border-b-0">
          <span className="inline-flex size-9 shrink-0 items-center justify-center rounded-md bg-muted text-foreground"><Icon name={iconFor(block.icon)} size={14} /></span>
          <div className="flex min-w-0 flex-col gap-2">
            <Link href={block.url} className="text-base font-medium text-foreground hover:underline hover:underline-offset-2">{block.capability}</Link>
            {(block.adds.length > 0 || block.keeps.length > 0) && (
              <ul className="flex flex-col gap-1.5 text-sm leading-[21px]">
                {block.adds.map((line, index) => <li key={`a${index}`} className="flex gap-3 text-foreground"><span aria-label="añade" className="w-3 shrink-0 font-mono text-success">+</span><InlineMarkdown text={line} /></li>)}
                {block.keeps.map((line, index) => <li key={`k${index}`} className="flex gap-3 text-muted-foreground"><span aria-label="no cambia" className="w-3 shrink-0 font-mono">=</span><InlineMarkdown text={line} /></li>)}
              </ul>
            )}
          </div>
        </div>
      ))}

      {story.changes_text && <p className="pt-4 text-sm leading-[21px] whitespace-pre-line text-body"><InlineMarkdown text={story.changes_text} /></p>}

      {story.changes.length === 0 && !doc && (
        <div className="flex items-center justify-between gap-4 pt-5 text-sm text-muted-foreground">
          <span>{done ? "Sin capacidades enlazadas." : "Aún no dice qué capacidades cambia."}</span>
          <a href={story.edit_url} className="inline-flex items-center gap-2 text-control hover:text-foreground"><Icon name="pencil" size={13} />Elegir capacidades</a>
        </div>
      )}
    </section>
  )
}

// Hecha con documentación pendiente (MT-91): punto naranja (atención), la capacidad candidata y «Copiar prompt», ligero.
function Documentation({ story, doc }: { story: StoryProps; doc: NonNullable<StoryProps["documentation"]> }) {
  return (
    <div className="mt-5 flex flex-col gap-4 rounded-xl border border-border bg-card p-5">
      <div className="flex gap-3">
        <span aria-hidden="true" className="mt-[7px] size-1.5 shrink-0 rounded-full bg-signal" />
        <div className="flex flex-col gap-1">
          <span className="text-sm font-medium text-foreground">
            {doc.kind === "unlinked" ? "Se cerró sin decir qué capacidades cambia" : "Se cerró sin actualizar sus páginas"}
          </span>
          <span className="text-sm leading-[21px] text-body">
            {doc.kind === "unlinked"
              ? "Hasta que lo diga, las páginas del producto no cuentan que esto ya funciona. Elige las capacidades: el aviso sigue hasta que sus páginas lo cuenten."
              : doc.relink
                ? "Las páginas de lo que cambia aún no cuentan cómo queda. Un agente las actualiza y vuelve a cerrarla."
                : "Las páginas de lo que cambia aún no cuentan cómo queda. El aviso se quita cuando un agente las actualiza."}
          </span>
        </div>
      </div>
      {doc.kind === "unlinked" && doc.candidate && (
        <div className="flex items-center gap-3 border-t border-border pt-4">
          <span className="inline-flex size-9 shrink-0 items-center justify-center rounded-md bg-muted text-foreground"><Icon name={iconFor(doc.candidate.icon)} size={14} /></span>
          <span className="flex min-w-0 flex-1 flex-col">
            <span className="text-sm font-medium text-foreground">{doc.candidate.title}</span>
            <span className="font-mono text-label tracking-[0.06em] text-muted-foreground uppercase">{[doc.candidate.area, "la que más encaja"].filter(Boolean).join(" · ")}</span>
          </span>
          <button type="button" onClick={() => router.post(doc.candidate!.link_url, {}, { preserveScroll: true })} className="inline-flex h-8 items-center rounded-md border border-border bg-card px-3 text-control text-foreground hover:bg-muted">Enlazar</button>
        </div>
      )}
      {doc.kind === "outdated" && (
        <ul className="flex flex-col border-t border-border pt-2">
          {doc.pages.map((page) => (
            <li key={page.url}><Link href={page.url} className="flex items-center gap-2.5 py-1.5 text-sm text-foreground hover:underline"><Icon name={iconFor(page.icon)} size={14} />{page.title}</Link></li>
          ))}
        </ul>
      )}
      <div className="flex flex-wrap items-center gap-x-3 gap-y-1">
        {doc.kind === "unlinked" && <a href={story.edit_url} className="inline-flex h-8 items-center gap-2 rounded-md px-2 text-control text-muted-foreground hover:text-foreground"><Icon name="stories" size={14} />Elegir otras</a>}
        <CopyForAgent text={doc.prompt} label="Copiar prompt" />
        {doc.kind === "outdated" && doc.relink && <span className="ml-auto hidden font-mono text-label text-muted-foreground sm:inline">mt done {story.ref}</span>}
      </div>
    </div>
  )
}

// El contexto completo, plegado: el resto del cuerpo tal cual.
function Context({ sections }: { sections: StoryProps["context"] }) {
  return (
    <Collapsible>
      <CollapsibleTrigger className="self-start text-left text-control text-foreground underline decoration-border underline-offset-[3px] hover:decoration-foreground data-open:no-underline">
        {sections.map((section) => section.title).filter(Boolean).join(", ") || "Contexto"}
      </CollapsibleTrigger>
      <CollapsiblePanel hiddenUntilFound className="flex flex-col gap-6 pt-5">
        {sections.map((section, index) => (
          <section key={index} className="flex flex-col gap-2">
            {section.title && <h3 className="text-[15px] leading-[18px] font-medium text-foreground"><InlineMarkdown text={section.title} /></h3>}
            <Prose blocks={section.blocks} />
          </section>
        ))}
      </CollapsiblePanel>
    </Collapsible>
  )
}

function Screens({ screens }: { screens: StoryProps["screens"] }) {
  const images = screens.filter((screen) => screen.src)
  const links = screens.filter((screen) => !screen.src)
  return (
    <div className="flex flex-col gap-3">
      <ul className="flex gap-2 overflow-x-auto pb-1">
        {images.map((screen) => (
          <li key={screen.code} className="flex w-[72px] shrink-0 flex-col items-center gap-1.5">
            <a href={screen.href} target="_blank" rel="noreferrer"><img src={screen.src!} alt={screen.title} className="aspect-[72/156] w-[72px] rounded-[10px] border border-border object-cover" /></a>
            <span className="font-mono text-label text-muted-foreground">{screen.code}</span>
          </li>
        ))}
        {images.length === 0 && (
          <li className="flex aspect-[72/156] w-[72px] shrink-0 flex-col items-center justify-center gap-2 rounded-[10px] border border-dashed border-muted-foreground/50 px-1.5 text-center text-label leading-[14px] text-muted-foreground">
            <Icon name="design" size={13} />
            Falta la pantalla
          </li>
        )}
      </ul>
      {links.map((screen) => (
        <a key={screen.code} href={screen.href} target="_blank" rel="noreferrer" className="flex items-center gap-2 text-control text-foreground hover:underline">
          <Icon name="link" size={13} className="shrink-0 text-muted-foreground" />{screen.title}
        </a>
      ))}
    </div>
  )
}

// Comentarios: el hilo y la caja para escribir (sin QA).
function Comments({ story }: { story: StoryProps }) {
  const [body, setBody] = useState("")
  const [sending, setSending] = useState(false)
  const send = () => {
    if (!body.trim()) return
    router.post(story.comment_url, { body }, { preserveScroll: true, onStart: () => setSending(true), onFinish: () => setSending(false), onSuccess: () => setBody("") })
  }
  return (
    <section id="comentarios" aria-labelledby="comentarios-titulo" className="flex flex-col gap-3">
      <div className="flex items-baseline justify-between gap-4 pb-1">
        <h2 id="comentarios-titulo" className="text-xl leading-6 font-medium tracking-[-0.01em] text-foreground">Comentarios</h2>
        {story.comments.length > 0 && <span className="font-mono text-label text-muted-foreground">{story.comments.length}</span>}
      </div>
      {story.comments.map((comment) => (
        <article key={comment.id} className="flex flex-col gap-2.5 rounded-xl border border-border bg-card p-5">
          <header className="flex items-center gap-2 text-label">
            {comment.agent && <Icon name="robot" size={13} aria-label="agente" className="text-muted-foreground" />}
            <span className="font-mono text-foreground">{comment.actor}</span>
            <span className="font-mono text-muted-foreground">{shortDate(comment.at)} · {time(comment.at)}</span>
          </header>
          <Prose blocks={comment.blocks} />
        </article>
      ))}
      <form
        onSubmit={(event) => { event.preventDefault(); send() }}
        className="flex flex-col gap-3 rounded-xl border border-border bg-card p-4"
      >
        <label htmlFor="comentario" className="sr-only">Escribe un comentario</label>
        <Textarea
          id="comentario"
          value={body}
          onChange={(event) => setBody(event.currentTarget.value)}
          onKeyDown={(event) => { if (event.key === "Enter" && (event.metaKey || event.ctrlKey)) { event.preventDefault(); send() } }}
          placeholder="Escribe un comentario…"
          rows={2}
          className="w-full resize-none bg-transparent text-sm text-foreground outline-none placeholder:text-muted-foreground"
        />
        <div className="flex items-center justify-between gap-3">
          <span className="hidden font-mono text-label text-muted-foreground sm:inline">mt comment {story.ref} "…"</span>
          <Button type="submit" variant="secondary" shortcut="⌘↵" disabled={sending || !body.trim()} className="ml-auto">Comentar</Button>
        </div>
      </form>
    </section>
  )
}

function Prose({ blocks }: { blocks: Block[] }): ReactNode {
  return (
    <div className="flex flex-col gap-3 text-sm leading-[21px] text-body">
      {blocks.map((block, index) => {
        switch (block.type) {
          case "heading":
            return <h4 key={index} className="pt-1 text-sm font-medium text-foreground"><InlineMarkdown text={block.text} /></h4>
          case "code":
            return <pre key={index} className="overflow-x-auto rounded-md border border-border bg-background p-3 font-mono text-control text-foreground">{block.text}</pre>
          case "list":
          case "ordered": {
            const List = block.type === "ordered" ? "ol" : "ul"
            return (
              <List key={index} className="flex flex-col">
                {block.items.map((item, position) => (
                  <li key={position} className="flex gap-2.5 border-t border-border py-2">
                    <span aria-hidden="true" className="w-[18px] shrink-0 font-mono text-label leading-[21px] text-muted-foreground">{block.type === "ordered" ? String(position + 1).padStart(2, "0") : "·"}</span>
                    <span><InlineMarkdown text={item} /></span>
                  </li>
                ))}
              </List>
            )
          }
          default:
            return <p key={index} className="whitespace-pre-line"><InlineMarkdown text={block.text} /></p>
        }
      })}
    </div>
  )
}
