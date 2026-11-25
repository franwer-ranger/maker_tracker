import { router, usePage } from "@inertiajs/react"
import { useShortcut } from "@ui-sdk/react/shortcuts"
import { useState } from "react"
import { Button } from "@/components/ui/button"
import { CopyForAgent } from "@/components/ui/copy-for-agent"
import { EmptyState } from "@/components/ui/empty-state"
import { Icon } from "@/components/ui/icons"
import { OpenQuestion } from "@/components/ui/open-question"
import { ProductCombo } from "@/components/ui/product-combo"
import { TaskTypeLabel, TaskTypeTile, taskTypes } from "@/components/ui/task-type"
import { AppShell } from "@/layouts/app-shell"

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

type Item = {
  kind: "answer" | "criteria" | "design" | "review"
  ref: string
  title: string
  milestone: string | null
  reason: string
  url: string
  edit_url: string
  ready_url?: string
  question?: Question
}

type WaitingItem = Pick<Item, "kind" | "ref" | "title" | "milestone" | "url">

type WorkshopProps = {
  items: Item[]
  waiting: number
  waiting_items: WaitingItem[]
  ready: number
  today: string
  prompt: string
  products: { key: string; name: string; url: string; count: number; logo: string | null }[]
}

// El taller (MT-97 · Paper «v1 · 6 · Taller»): la portada. Un producto cada vez, lo siguiente que te toca
// definir (como mucho 5, en el orden del roadmap) con su única acción, y el resto plegado.
export default function Workshop({ workshop }: { workshop: WorkshopProps }) {
  const { project } = usePage().props
  const [first, ...rest] = workshop.items
  const copyLabel = workshop.items.length > 1 ? `Copiar las ${workshop.items.length} para tu agente` : "Copiar para tu agente"
  // En móvil, como en Paper: «Copiar las 5», para que quepa junto a las listas.
  const copyShortLabel = workshop.items.length > 1 ? `Copiar las ${workshop.items.length}` : "Copiar"

  return (
    <AppShell title={`Taller · ${project.name}`} active="workshop" copy={workshop.prompt}>
      <div className="flex h-12 shrink-0 items-center border-b border-border px-5 text-control text-foreground md:hidden">Taller</div>
      <div className="mx-auto flex w-full max-w-[780px] flex-col gap-[30px] px-5 pt-8 pb-12 md:px-6 md:pt-14">
        <header className="flex flex-col gap-3.5">
          <p className="font-mono text-label leading-[14px] tracking-[0.12em] text-muted-foreground uppercase">{workshop.today}</p>
          <h1 className="font-display text-[40px] leading-[1.05] text-foreground md:text-[56px] md:leading-[56px]">Lo que te toca definir</h1>
        </header>

        <div className="flex flex-wrap items-center justify-between gap-3">
          <div className="w-full sm:w-auto">
            <ProductCombo products={workshop.products} current={project.key} tone="panel" />
          </div>
          <div className="flex items-center gap-3.5">
            <span className="text-control whitespace-nowrap text-muted-foreground">
              <span className="font-mono">{workshop.ready}</span> {workshop.ready === 1 ? "lista" : "listas"} para construir
            </span>
            {first && <CopyForAgent text={workshop.prompt} label={copyLabel} shortLabel={copyShortLabel} shortcut="mod+shift+c" />}
          </div>
        </div>

        {first ? (
          <>
            <First item={first} />
            {rest.length > 0 && (
              <section aria-labelledby="despues" className="flex flex-col">
                <h2 id="despues" className="px-1 pb-2.5 font-mono text-label leading-[14px] tracking-[0.12em] text-muted-foreground uppercase">Después, en el orden del roadmap</h2>
                <ol className="flex flex-col">
                  {rest.map((item, index) => <Row key={item.ref} item={item} index={index + 2} />)}
                </ol>
              </section>
            )}
            {workshop.waiting > 0 && <Waiting count={workshop.waiting} items={workshop.waiting_items} productName={project.name} />}
          </>
        ) : (
          <div className="rounded-xl border border-border bg-card">
            <EmptyState figure="calm" title="Nada que definir ahora">
              {workshop.ready > 0
                ? `Hay ${workshop.ready} ${workshop.ready === 1 ? "historia lista" : "historias listas"} para construir en ${project.name}. Buen momento para pensar en lo siguiente.`
                : `Nada espera una definición tuya en ${project.name}. Buen momento para pensar en lo siguiente.`}
            </EmptyState>
          </div>
        )}
      </div>
    </AppShell>
  )
}

// Lo primero, grande y con el único botón en tinta de la pantalla.
function First({ item }: { item: Item }) {
  useShortcut(item.kind === "review" ? "l" : null, () => markReady(item), { description: "Marcar como Lista" })

  if (item.kind === "answer" && item.question) {
    const question = item.question
    return (
      <div className="flex flex-col gap-3">
        <FirstHeading item={item} />
        <OpenQuestion
          question={question.title}
          context={question.context ?? undefined}
          blocks={`${question.actor} · ${item.ref}`}
          options={question.options.map((option) => ({ ...option, recommended: String(question.recommended) === option.value }))}
          onAnswer={(value) => answer(question, value)}
        />
      </div>
    )
  }

  return (
    <article className="flex gap-[22px] rounded-xl border border-border bg-card p-5 md:p-6">
      <span className="hidden md:block"><TaskTypeTile type={item.kind} /></span>
      <div className="flex min-w-0 flex-1 flex-col gap-3">
        <FirstHeading item={item} />
        <h2 className="text-xl leading-7 font-medium tracking-[-0.015em] text-foreground md:text-2xl md:leading-[30px]">{item.title}</h2>
        <p className="text-sm leading-[21px] text-body">{item.reason}</p>
        <div className="flex items-center gap-2.5 pt-1">
          <PrimaryAction item={item} />
          <a href={item.url} className="rounded-md px-3 py-2 text-sm text-foreground hover:bg-muted">Ver historia</a>
        </div>
      </div>
    </article>
  )
}

function FirstHeading({ item }: { item: Item }) {
  return (
    <div className="flex flex-wrap items-center justify-between gap-2">
      <span className="font-mono text-label leading-[14px] tracking-[0.1em] text-foreground uppercase">Primero · {taskTypes[item.kind].label}</span>
      <span className="font-mono text-label leading-[14px] text-muted-foreground">{[item.ref, item.milestone].filter(Boolean).join(" · ")}</span>
    </div>
  )
}

function PrimaryAction({ item }: { item: Item }) {
  if (item.kind === "review") return <Button shortcut="L" onClick={() => markReady(item)}>Marcar como Lista</Button>
  return <Button render={<a href={actionUrl(item)} />}>{actionLabel(item)}</Button>
}

// El resto: lista compacta con su tipo (icono + nombre) y su acción secundaria a la derecha.
function Row({ item, index }: { item: Item; index: number }) {
  const [answering, setAnswering] = useState(false)
  const question = item.question

  return (
    <li className="flex flex-col gap-4 border-t border-border px-1 py-4">
      <div className="grid grid-cols-[28px_1fr] items-start gap-3.5 sm:grid-cols-[28px_1fr_auto]">
        <span className="font-mono text-control leading-[22px] text-muted-foreground">{String(index).padStart(2, "0")}</span>
        <div className="flex min-w-0 flex-col gap-[5px]">
          <a href={item.url} className="text-base leading-[22px] font-medium text-foreground hover:underline">{item.title}</a>
          <p className="hidden text-control leading-[19px] text-muted-foreground sm:block">
            {item.reason} <span className="font-mono text-label">{[item.ref, item.milestone].filter(Boolean).join(" · ")}</span>
          </p>
          {/* En móvil, como en Paper: tipo y referencia en una línea, sin botón (la fila lleva a la historia). */}
          <p className="flex flex-wrap items-center gap-x-2.5 gap-y-1 sm:hidden">
            <TaskTypeLabel type={item.kind} className="text-[10px]" />
            <span className="font-mono text-label text-muted-foreground">{[item.ref, item.milestone].filter(Boolean).join(" · ")}</span>
          </p>
        </div>
        <div className="hidden sm:flex sm:flex-col sm:items-end sm:gap-2">
          <span><TaskTypeLabel type={item.kind} className="text-[10px]" /></span>
          {item.kind === "review" ? (
            <Button variant="secondary" className="h-7 text-control" onClick={() => markReady(item)}>Marcar como Lista</Button>
          ) : item.kind === "answer" && question ? (
            <Button variant="secondary" className="h-7 text-control" aria-expanded={answering} onClick={() => setAnswering((open) => !open)}>
              {answering ? "Cerrar" : "Responder"}
            </Button>
          ) : (
            <Button variant="secondary" className="h-7 text-control" render={<a href={actionUrl(item)} />}>{actionLabel(item)}</Button>
          )}
        </div>
      </div>
      {answering && question && (
        <div className="hidden sm:block sm:pl-[42px]">
          <OpenQuestion
            question={question.title}
            context={question.context ?? undefined}
            blocks={question.actor}
            options={question.options.map((option) => ({ ...option, recommended: String(question.recommended) === option.value }))}
            onAnswer={(value) => answer(question, value)}
          />
        </div>
      )}
    </li>
  )
}

// El resto en definición, plegado con su número; «Mostrar» lo despliega aquí mismo, una línea por historia.
function Waiting({ count, items, productName }: { count: number; items: WaitingItem[]; productName: string }) {
  const [open, setOpen] = useState(false)

  return (
    <section className="flex flex-col border-t border-border">
      <div className="flex items-center justify-between gap-4 px-1 py-3.5">
        <p className="text-sm text-muted-foreground">
          En espera · <span className="font-mono text-foreground">{count}</span> más en definición
          <span className="hidden sm:inline"> de {productName} · suben cuando les toque en el roadmap</span>
        </p>
        <button
          type="button"
          aria-expanded={open}
          aria-controls="en-espera"
          onClick={() => setOpen((value) => !value)}
          className="flex items-center gap-1 rounded-sm text-control text-muted-foreground hover:text-foreground"
        >
          <span className={open ? undefined : "sr-only sm:not-sr-only"}>{open ? "Ocultar" : "Mostrar"}</span>
          <Icon name="chevronRight" size={12} className={open ? "hidden" : "sm:hidden"} />
        </button>
      </div>
      {open && (
        <ul id="en-espera" className="flex flex-col">
          {items.map((item) => (
            <li key={item.ref} className="flex flex-wrap items-baseline justify-between gap-x-4 gap-y-1 border-t border-border px-1 py-2.5">
              <a href={item.url} className="min-w-0 text-sm text-foreground hover:underline">{item.title}</a>
              <span className="flex items-center gap-2.5">
                <TaskTypeLabel type={item.kind} className="text-[10px]" />
                <span className="font-mono text-label text-muted-foreground">{[item.ref, item.milestone].filter(Boolean).join(" · ")}</span>
              </span>
            </li>
          ))}
        </ul>
      )}
    </section>
  )
}

function actionLabel(item: Item) {
  switch (item.kind) {
    case "criteria": return "Escribirlos"
    case "design": return "Añadir mockup"
    case "answer": return "Ver preguntas"
    default: return "Ver historia"
  }
}

function actionUrl(item: Item) {
  return item.kind === "criteria" || item.kind === "design" ? item.edit_url : item.url
}

function markReady(item: Item) {
  if (item.ready_url) router.post(item.ready_url, {}, { preserveScroll: true })
}

function answer(question: Question, option: string) {
  router.post(question.answer_url, { question_id: question.id, option }, { preserveScroll: true })
}

