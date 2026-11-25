import { Link, useForm, usePage } from "@inertiajs/react"
import { Command, CommandEmpty, CommandInput, CommandItem, CommandItemText, CommandList } from "@ui-sdk/react/command"
import { Input } from "@ui-sdk/react/input"
import { Popover, PopoverContent, PopoverTitle, PopoverTrigger } from "@ui-sdk/react/popover"
import { Textarea } from "@ui-sdk/react/textarea"
import { type FormEvent, type KeyboardEvent, type ReactNode, useEffect, useMemo, useRef, useState } from "react"
import { CopyForAgent } from "@/components/ui/copy-for-agent"
import { cx } from "@/components/ui/cx"
import { Eyebrow } from "@/components/ui/eyebrow"
import { Icon, type IconName } from "@/components/ui/icons"
import { Kbd } from "@/components/ui/kbd"
import { StateBadge, type StoryState } from "@/components/ui/state"
import { AppShell } from "@/layouts/app-shell"

const isApple = /Mac|iPhone|iPad/.test(navigator.platform)

type Props = {
  story: {
    ref: string
    number: number
    title: string
    state: StoryState
    body: string
    milestone_id: number | null
    capabilities: string[]
    labels: string
    mockup: string
    version: number
    open_questions: number
    url: string
    contrast_url: string
    show_url: string
    copy: string
  }
  milestones: { id: number; label: string }[]
  capabilities: { slug: string; title: string }[]
  guides: { heading: string; guide: string | null }[]
}

type Contrast = { kind: "decision" | "story" | "brief"; reference: string; title: string; excerpt: string | null; url: string | null }

// Una sección `## …` del cuerpo: su texto sin los comentarios de la plantilla (las guías), que se guardan
// aparte y vuelven al juntarlo. `present`: si estaba en el cuerpo; las de la plantilla que faltan se enseñan
// vacías y solo se añaden si se escribe algo en ellas.
type Section = { heading: string; comments: string[]; text: string; present: boolean }

const COMMENT = /^\s*<!--[\s\S]*?-->\s*$/

// Lo que dice Paper para las secciones que lo concretan; el resto, la guía de la plantilla (MT-52).
const GUIDES: Record<string, string> = {
  Historia: "Una frase: quién, qué quiere y para qué. Si cuesta escribirla, la historia aún no está clara.",
}
const PLACEHOLDERS: Record<string, string> = {
  "Criterios de aceptación": "Qué tiene que pasar para darla por buena, uno por línea, comprobables.",
  "Fuera de alcance": "Lo que no se hace aquí, para que nadie lo añada.",
}
const STORY_TEMPLATE = "Como (usuario), quiero (hacer algo), para (cumplir un objetivo)."

function parseBody(body: string, template: string[]) {
  const chunks = body.replace(/\r\n/g, "\n").split(/^(?=## )/m)
  const preamble = chunks[0].startsWith("## ") ? "" : chunks.shift()!.trim()
  const sections: Section[] = chunks.map((chunk) => {
    const [first, ...rest] = chunk.split("\n")
    const comments: string[] = []
    const lines: string[] = []
    // Solo los comentarios del principio son guías; los de en medio son del texto.
    for (const line of rest) {
      if (lines.every((l) => !l.trim()) && COMMENT.test(line)) comments.push(line.trim())
      else lines.push(line)
    }
    return { heading: first.replace(/^## /, "").trim(), comments, text: lines.join("\n").trim(), present: true }
  })
  // Las de la plantilla que faltan, en su sitio de la plantilla.
  template.forEach((heading, index) => {
    if (sections.some((section) => section.heading === heading)) return
    const before = template.slice(0, index).reverse().find((previous) => sections.some((s) => s.heading === previous))
    const at = before ? sections.findIndex((s) => s.heading === before) + 1 : 0
    sections.splice(at, 0, { heading, comments: [], text: "", present: false })
  })
  return { preamble, sections }
}

function joinBody(preamble: string, sections: Section[]) {
  const parts = preamble.trim() ? [preamble.trim()] : []
  for (const section of sections) {
    if (!section.present && !section.text.trim()) continue
    parts.push([`## ${section.heading}`, ...section.comments, ...(section.text.trim() ? ["", section.text.trim()] : [])].join("\n"))
  }
  return `${parts.join("\n\n")}\n`
}

const sectionText = (sections: Section[], heading: string) => sections.find((s) => s.heading === heading)?.text.trim() ?? ""

// Editar una historia (MT-112, «v1 · 9 · Editar»): título en serif, propiedades, las secciones de la plantilla con
// la guía de la enfocada y, al lado, lo que le falta para Lista y el contraste con lo decidido (`mt check`).
// Barra de guardar abajo con ⌘S; en móvil fija y con cuántas faltan. El conflicto de versión llega como `errors.base`.
export default function StoryEdit({ story, milestones, capabilities, guides }: Props) {
  const { nav } = usePage().props
  const template = guides.map((guide) => guide.heading)
  const initial = useMemo(() => parseBody(story.body, template), [story.body]) // eslint-disable-line react-hooks/exhaustive-deps
  const [preamble] = useState(initial.preamble)
  const [sections, setSections] = useState(initial.sections)
  const [raw, setRaw] = useState<string | null>(null)
  const [focused, setFocused] = useState<string | null>(null)
  const [bodyTouched, setBodyTouched] = useState(false)

  const form = useForm({
    title: story.title,
    milestone_id: story.milestone_id,
    capabilities: story.capabilities,
    labels: story.labels,
    mockup: story.mockup,
    version: story.version,
  })
  const errors = form.errors as Record<string, string | string[] | undefined>
  const body = raw ?? (bodyTouched ? joinBody(preamble, sections) : story.body)
  const dirty = form.isDirty || body !== story.body

  const setSection = (heading: string, text: string) => {
    setBodyTouched(true)
    setSections((current) => current.map((section) => (section.heading === heading ? { ...section, text } : section)))
  }

  // «Markdown»: el cuerpo entero en crudo; al volver, se parte otra vez en secciones.
  const toggleRaw = () => {
    if (raw === null) setRaw(joinBody(preamble, sections))
    else {
      setSections(parseBody(raw, template).sections)
      setBodyTouched(true)
      setRaw(null)
    }
  }

  const labels = form.data.labels.split(",").map((label) => label.trim()).filter(Boolean)
  const currentSections = raw === null ? sections : parseBody(raw, template).sections
  const storyLine = sectionText(currentSections, "Historia")
  const missing = [
    { label: "Contexto", done: !!sectionText(currentSections, "Contexto") },
    { label: "Historia en una frase", done: !!storyLine && storyLine !== STORY_TEMPLATE },
    { label: "Criterios de aceptación", done: /^\s*[-*] \[[ xX]\]/m.test(body) },
    { label: "Fuera de alcance", done: !!sectionText(currentSections, "Fuera de alcance") },
    { label: "Hito", done: !!form.data.milestone_id },
    ...(labels.includes("ui") ? [{ label: "Mockup (es de interfaz)", done: !!form.data.mockup.trim() }] : []),
    ...(sectionText(currentSections, "Preguntas abiertas") || story.open_questions > 0 ? [{ label: "Preguntas abiertas respondidas", done: false }] : []),
  ]
  const left = missing.filter((item) => !item.done).length

  const contrast = useContrast(story.contrast_url, [form.data.title, sectionText(currentSections, "Contexto"), storyLine].join("\n"))

  const submit = (event?: FormEvent) => {
    event?.preventDefault()
    if (form.processing) return
    form.transform((data) => ({ story: { ...data, body } }))
    form.patch(story.url, { preserveScroll: true, preserveState: true })
  }

  // ⌘S / Ctrl+S también desde dentro de los textos (los atajos de la página no miran los campos).
  const submitRef = useRef(submit)
  submitRef.current = submit
  useEffect(() => {
    const onKey = (event: globalThis.KeyboardEvent) => {
      if (event.key.toLowerCase() === "s" && (event.metaKey || event.ctrlKey) && !event.shiftKey && !event.altKey) {
        event.preventDefault()
        submitRef.current()
      }
    }
    window.addEventListener("keydown", onKey)
    return () => window.removeEventListener("keydown", onKey)
  }, [])

  // Salir con cambios sin guardar pregunta antes (recargar o cerrar la pestaña).
  useEffect(() => {
    if (!dirty || form.processing) return
    const warn = (event: BeforeUnloadEvent) => event.preventDefault()
    window.addEventListener("beforeunload", warn)
    return () => window.removeEventListener("beforeunload", warn)
  }, [dirty, form.processing])

  const crumbs = [{ label: "Historias", href: nav.board }, { label: story.ref, href: story.show_url }, { label: "Editar" }]
  const actions = (
    <>
      <CopyForAgent text={story.copy} shortcut="mod+shift+c" />
      <button type="button" onClick={toggleRaw} aria-pressed={raw !== null}
        className={cx("inline-flex h-8 items-center gap-[7px] rounded-[7px] px-2 text-control hover:text-foreground", raw !== null ? "bg-muted text-foreground" : "text-muted-foreground")}>
        <Icon name="file" size={14} />Markdown
      </button>
    </>
  )

  const guideFor = (heading: string) => GUIDES[heading] ?? guides.find((guide) => guide.heading === heading)?.guide ?? null

  return (
    <AppShell title={`Editar ${story.ref} · ${form.data.title}`} active="stories" crumbs={crumbs} copy={story.copy} actions={actions} ownMobileBar>
      <form noValidate onSubmit={submit} aria-label={`Editar ${story.ref}`} className="flex grow flex-col">
        <nav aria-label="Migas" className="border-b border-border px-5 py-3.5 font-mono text-xs text-foreground md:hidden">
          <Link href={nav.board}>Historias</Link> / <a href={story.show_url}>{story.ref}</a> / Editar
        </nav>

        <div className="flex grow flex-col gap-10 px-5 pt-[22px] pb-[150px] lg:flex-row lg:items-start lg:gap-12 lg:pt-10 lg:pr-12 lg:pb-[120px] lg:pl-[72px]">
          <div className="flex min-w-0 flex-col gap-6 lg:w-[720px] lg:shrink lg:gap-[30px]">
            <header className="flex flex-col gap-3 lg:gap-3.5">
              <div className="flex items-center gap-2.5">
                <StateBadge state={story.state} />
                {!form.data.milestone_id && <Eyebrow className="leading-[14px] tracking-[0.1em]">Bandeja de ideas</Eyebrow>}
              </div>
              <Textarea
                aria-label="Título"
                value={form.data.title}
                onChange={(event) => form.setData("title", event.currentTarget.value.replace(/\n/g, " "))}
                onKeyDown={(event: KeyboardEvent) => { if (event.key === "Enter") event.preventDefault() }}
                rows={1}
                className="w-full resize-none bg-transparent font-display text-[34px] leading-[38px] text-foreground outline-none [field-sizing:content] lg:text-[44px] lg:leading-[48px]"
              />
              {errors.title && <p role="alert" className="text-control text-destructive">El título no puede quedar vacío.</p>}
            </header>

            {errors.base && (
              <div role="alert" className="flex flex-col gap-2 rounded-[10px] border border-border bg-card px-4 py-3 sm:flex-row sm:items-center sm:justify-between">
                <p className="flex items-start gap-2.5 text-control leading-[19px] text-foreground">
                  <span aria-hidden="true" className="mt-1.5 size-1.5 shrink-0 rounded-full bg-signal" />
                  {[errors.base].flat().join(" ")}
                </p>
                <a href={story.url} className="shrink-0 text-control text-foreground underline decoration-border underline-offset-[3px] hover:decoration-foreground">Recargar</a>
              </div>
            )}

            <Properties form={form} milestones={milestones} capabilities={capabilities} errors={errors} />

            <div className="lg:hidden"><ContrastList results={contrast} compact /></div>

            {raw !== null ? (
              <Textarea
                aria-label="Cuerpo en markdown"
                value={raw}
                onChange={(event) => setRaw(event.currentTarget.value)}
                className="min-h-[420px] w-full resize-y rounded-[10px] border border-border bg-card p-4 font-mono text-[13px] leading-[21px] text-foreground outline-none [field-sizing:content] focus:border-foreground"
              />
            ) : (
              <>
                {preamble && <p className="whitespace-pre-wrap text-[15px] leading-6 text-body">{preamble}</p>}
                {sections.map((section) => (
                  <SectionEditor
                    key={section.heading}
                    section={section}
                    guide={guideFor(section.heading)}
                    placeholder={PLACEHOLDERS[section.heading] ?? guideFor(section.heading) ?? "Escribe aquí."}
                    focused={focused === section.heading}
                    onFocus={() => setFocused(section.heading)}
                    onBlur={() => setFocused((current) => (current === section.heading ? null : current))}
                    onChange={(text) => setSection(section.heading, text)}
                  />
                ))}
              </>
            )}
          </div>

          <aside className="hidden w-[320px] shrink-0 flex-col gap-[26px] pt-1 lg:flex">
            <section aria-labelledby="antes-de-lista" className="flex flex-col gap-2.5">
              <h2 id="antes-de-lista" className="contents"><Eyebrow className="leading-[14px] tracking-[0.1em]">Antes de pasarla a Lista</Eyebrow></h2>
              <Missing items={missing} />
            </section>
            <section aria-labelledby="contrasta" className="flex flex-col gap-2.5">
              <h2 id="contrasta" className="contents"><Eyebrow className="leading-[14px] tracking-[0.1em]">Contrasta con lo decidido</Eyebrow></h2>
              <ContrastList results={contrast} />
              <p className="text-xs text-muted-foreground">Lo calcula <span className="font-mono">mt check</span> mientras escribes.</p>
            </section>
          </aside>
        </div>

        <SaveBar dirty={dirty} left={left} missing={missing} processing={form.processing} discardUrl={story.show_url} />
      </form>
    </AppShell>
  )
}

type StoryForm = ReturnType<typeof useForm<{ title: string; milestone_id: number | null; capabilities: string[]; labels: string; mockup: string; version: number }>>

function Property({ icon, label, children }: { icon: IconName; label: string; children: ReactNode }) {
  return (
    <div className="grid grid-cols-[96px_1fr] items-center gap-2.5 py-[7px] lg:grid-cols-[120px_1fr] lg:gap-3">
      <span className="flex items-center gap-[7px] text-control text-muted-foreground lg:gap-2"><Icon name={icon} size={13} />{label}</span>
      <div className="flex min-w-0 flex-wrap items-center gap-1.5 lg:gap-2">{children}</div>
    </div>
  )
}

function Properties({ form, milestones, capabilities, errors }: { form: StoryForm; milestones: Props["milestones"]; capabilities: Props["capabilities"]; errors: Record<string, string | string[] | undefined> }) {
  const milestone = milestones.find((item) => item.id === form.data.milestone_id)
  const chosen = form.data.capabilities
  const titleOf = (slug: string) => capabilities.find((item) => item.slug === slug)?.title ?? slug

  return (
    <div className="flex flex-col border-y border-border py-1 lg:py-1.5">
      <Property icon="roadmap" label="Hito">
        <Picker
          label="Elegir hito"
          trigger={<span className={cx("flex items-center gap-1.5 text-control", milestone ? "text-foreground" : "text-muted-foreground")}>{milestone?.label ?? "Sin hito"}<Icon name="chevronDown" size={12} strokeWidth={2} className="text-muted-foreground" /></span>}
          items={[{ value: "", label: "Sin hito" }, ...milestones.map((item) => ({ value: String(item.id), label: item.label }))]}
          selected={form.data.milestone_id ? String(form.data.milestone_id) : ""}
          onChoose={(value) => form.setData("milestone_id", value ? Number(value) : null)}
        />
      </Property>
      <Property icon="design" label="Cambia">
        {chosen.map((slug) => (
          <span key={slug} className="inline-flex items-center gap-1.5 rounded-full bg-card py-[3px] pr-1.5 pl-[7px] text-xs text-foreground shadow-[0_0_0_1px_var(--border)]">
            <Icon name="design" size={12} />{titleOf(slug)}
            <button type="button" aria-label={`Quitar ${titleOf(slug)}`} onClick={() => form.setData("capabilities", chosen.filter((item) => item !== slug))} className="rounded-full px-0.5 text-muted-foreground hover:text-foreground">×</button>
          </span>
        ))}
        {capabilities.some((item) => !chosen.includes(item.slug)) && (
          <Picker
            label="Añadir capacidad"
            trigger={<span className="text-control text-muted-foreground hover:text-foreground">+ capacidad</span>}
            items={capabilities.filter((item) => !chosen.includes(item.slug)).map((item) => ({ value: item.slug, label: item.title }))}
            onChoose={(value) => form.setData("capabilities", [...chosen, value])}
          />
        )}
        {chosen.length === 0 && capabilities.length === 0 && <span className="text-control text-muted-foreground">Aún no hay páginas de capacidades</span>}
      </Property>
      <Property icon="stories" label="Etiquetas">
        <Input
          aria-label="Etiquetas"
          value={form.data.labels}
          onValueChange={(value) => form.setData("labels", value)}
          placeholder="ui, ios…"
          className="w-full bg-transparent font-mono text-xs text-foreground outline-none placeholder:font-sans placeholder:text-control placeholder:text-muted-foreground focus-visible:shadow-none"
        />
      </Property>
      <Property icon="design" label="Mockup">
        <Input
          aria-label="Mockup"
          type="url"
          value={form.data.mockup}
          onValueChange={(value) => form.setData("mockup", value)}
          placeholder="Pega un enlace"
          className="w-full truncate bg-transparent text-control text-foreground outline-none placeholder:text-muted-foreground focus-visible:shadow-none"
        />
        {errors.mockup && <span role="alert" className="text-xs text-destructive">{[errors.mockup].flat().join(" ")}</span>}
      </Property>
    </div>
  )
}

// Desplegable con buscador (Popover + Command de UI SDK, como el combo de producto).
function Picker({ label, trigger, items, selected, onChoose }: { label: string; trigger: ReactNode; items: { value: string; label: string }[]; selected?: string; onChoose: (value: string) => void }) {
  const [open, setOpen] = useState(false)
  return (
    <Popover open={open} onOpenChange={setOpen}>
      <PopoverTrigger className="rounded-sm">{trigger}</PopoverTrigger>
      <PopoverContent side="bottom" align="start" sideOffset={6} className="z-50 w-[300px] max-w-[calc(100vw-32px)] overflow-hidden rounded-xl border border-border bg-card text-foreground shadow-[0_12px_32px_rgba(15,15,17,0.14)]">
        <PopoverTitle className="sr-only">{label}</PopoverTitle>
        <Command onAction={(value) => { setOpen(false); onChoose(value) }} className="flex flex-col">
          <div className="flex h-11 items-center gap-2.5 border-b border-border px-3 text-muted-foreground">
            <Icon name="search" size={14} />
            <CommandInput aria-label={label} placeholder="Buscar…" className="h-full flex-1 bg-transparent text-sm text-foreground outline-none placeholder:text-muted-foreground focus-visible:shadow-none" />
          </div>
          <CommandEmpty className="px-3 py-4 text-control text-muted-foreground not-data-empty:hidden">{(state) => `Nada con «${state.query}».`}</CommandEmpty>
          <CommandList className="max-h-72 overflow-y-auto">
            {items.map((item) => (
              <CommandItem key={item.value || "none"} value={item.value} label={item.label} className="flex h-10 cursor-default items-center gap-2.5 px-3 text-sm data-highlighted:bg-muted">
                <CommandItemText className="min-w-0 flex-1 truncate [&_mark]:bg-transparent [&_mark]:font-semibold [&_mark]:text-foreground">{item.label}</CommandItemText>
                {selected === item.value && <Icon name="check" size={13} className="text-muted-foreground" />}
              </CommandItem>
            ))}
          </CommandList>
        </Command>
      </PopoverContent>
    </Popover>
  )
}

// Una sección de la plantilla: su título y el texto; la enfocada, en blanco con borde de tinta y su guía.
function SectionEditor({ section, guide, placeholder, focused, onFocus, onBlur, onChange }: { section: Section; guide: string | null; placeholder: string; focused: boolean; onFocus: () => void; onBlur: () => void; onChange: (text: string) => void }) {
  const id = `seccion-${section.heading.toLowerCase().normalize("NFKD").replace(/[^a-z0-9]+/g, "-")}`
  const criteria = section.heading === "Criterios de aceptación"

  // En los criterios, Enter sigue la lista de casillas.
  const onKeyDown = (event: KeyboardEvent<HTMLTextAreaElement>) => {
    if (!criteria || event.key !== "Enter" || event.shiftKey || event.metaKey || event.ctrlKey) return
    const area = event.currentTarget
    const start = area.selectionStart
    const line = area.value.slice(area.value.lastIndexOf("\n", start - 1) + 1, start)
    const box = line.match(/^(\s*[-*] )\[[ xX]\] /)
    if (!box) return
    event.preventDefault()
    const insert = `\n${box[1]}[ ] `
    const next = area.value.slice(0, start) + insert + area.value.slice(area.selectionEnd)
    onChange(next)
    requestAnimationFrame(() => area.setSelectionRange(start + insert.length, start + insert.length))
  }

  return (
    <section
      aria-labelledby={id}
      className={cx(
        "flex flex-col gap-2 rounded-[10px]",
        focused && "-mx-3.5 bg-card px-3.5 py-3 shadow-[0_0_0_1.5px_var(--foreground)] lg:-mx-4 lg:px-4 lg:py-3.5",
      )}
    >
      <label id={id} htmlFor={`${id}-texto`} className="text-base leading-5 font-medium text-foreground lg:text-lg lg:leading-[22px]">{section.heading}</label>
      <Textarea
        id={`${id}-texto`}
        value={section.text}
        onChange={(event) => onChange(event.currentTarget.value)}
        onKeyDown={onKeyDown}
        onFocus={onFocus}
        onBlur={onBlur}
        placeholder={placeholder}
        rows={1}
        className="w-full resize-none bg-transparent text-[15px] leading-[23px] text-body outline-none [field-sizing:content] placeholder:text-kbd focus-visible:shadow-none lg:leading-6"
      />
      {focused && guide && (
        <p className="flex items-start gap-2 pt-0.5 text-xs leading-[17px] text-muted-foreground lg:pt-1 lg:leading-[18px]">
          <Icon name="question" size={13} className="mt-px" />{guide}
        </p>
      )}
    </section>
  )
}

function Missing({ items }: { items: { label: string; done: boolean }[] }) {
  return (
    <ul className="flex flex-col gap-[9px]">
      {items.map((item) => (
        <li key={item.label} className={cx("flex items-center gap-2.5 text-control", item.done ? "text-foreground" : "text-muted-foreground")}>
          {item.done ? (
            <span className="flex size-4 shrink-0 items-center justify-center rounded-full bg-foreground text-background"><Icon name="check" size={10} strokeWidth={2.4} /></span>
          ) : (
            <span className="size-4 shrink-0 rounded-full shadow-[inset_0_0_0_1.5px_var(--kbd)]" />
          )}
          <span>{item.label}<span className="sr-only">{item.done ? ": hecho" : ": falta"}</span></span>
        </li>
      ))}
    </ul>
  )
}

function ContrastList({ results, compact = false }: { results: Contrast[] | null; compact?: boolean }) {
  if (results === null) return compact ? null : <p className="text-xs text-muted-foreground">Escribe la historia para contrastarla.</p>
  if (results.length === 0) return compact ? null : <p className="text-xs text-muted-foreground">Nada de lo decidido parece tocarla.</p>
  return (
    <ul className="flex flex-col gap-2.5" aria-live="polite">
      {results.map((result) => {
        const lead = result.kind === "decision" ? `Toca ${result.reference}` : result.kind === "story" ? `Se parece a ${result.reference}` : "Toca el brief"
        const body = (
          <>
            <span aria-hidden="true" className="mt-1.5 size-1.5 shrink-0 rounded-full bg-signal" />
            <span className="flex min-w-0 flex-col gap-[3px]">
              <span className="text-control leading-[19px] text-foreground">{lead}: {result.title}</span>
              {result.excerpt && <span className="line-clamp-3 text-xs leading-[17px] text-muted-foreground">{result.excerpt}</span>}
            </span>
          </>
        )
        const className = "flex items-start gap-2.5 rounded-[10px] bg-card px-3.5 py-3 shadow-[0_0_0_1px_var(--border)]"
        return (
          <li key={`${result.kind}-${result.reference}-${result.title}`}>
            {result.url ? <a href={result.url} target="_blank" rel="noreferrer" className={cx(className, "hover:shadow-[0_0_0_1px_var(--muted-foreground)]")}>{body}</a> : <div className={className}>{body}</div>}
          </li>
        )
      })}
    </ul>
  )
}

// `mt check` con lo escrito, un momento después de dejar de escribir. null: aún nada que contrastar.
function useContrast(url: string, text: string) {
  const [results, setResults] = useState<Contrast[] | null>(null)
  const query = text.trim()
  useEffect(() => {
    if (query.length < 8) return
    const controller = new AbortController()
    const timer = setTimeout(() => {
      fetch(`${url}?${new URLSearchParams({ text: query })}`, { headers: { Accept: "application/json" }, signal: controller.signal })
        .then((response) => (response.ok ? response.json() : { results: [] }))
        .then((data: { results: Contrast[] }) => setResults(data.results))
        .catch(() => {})
    }, 700)
    return () => { clearTimeout(timer); controller.abort() }
  }, [url, query])
  return results
}

function SaveBar({ dirty, left, missing, processing, discardUrl }: { dirty: boolean; left: number; missing: { label: string; done: boolean }[]; processing: boolean; discardUrl: string }) {
  const status = (
    <span className="flex items-center gap-2 text-xs text-muted-foreground lg:text-control">
      <span aria-hidden="true" className={cx("hidden size-1.5 rounded-full lg:inline", dirty ? "bg-kbd" : "bg-transparent")} />
      {dirty ? <><span className="lg:hidden">Sin guardar</span><span className="hidden lg:inline">Cambios sin guardar</span></> : "Sin cambios"}
    </span>
  )
  return (
    <div className="fixed inset-x-0 bottom-0 z-20 flex flex-col gap-2.5 border-t border-border bg-background px-4 pt-3 pb-[max(16px,env(safe-area-inset-bottom))] md:sticky lg:items-center lg:p-3.5">
      <div className="flex items-center justify-between lg:hidden">
        <Popover>
          <PopoverTrigger className="text-xs text-muted-foreground">
            {left > 0 ? <>Para pasarla a Lista faltan <span className="text-foreground">{left}</span> · ver</> : "Lista para pasarla a Lista · ver"}
          </PopoverTrigger>
          <PopoverContent side="top" align="start" sideOffset={8} className="z-50 w-[280px] rounded-xl border border-border bg-card p-4 shadow-lg">
            <PopoverTitle className="pb-2.5"><Eyebrow className="tracking-[0.1em]">Antes de pasarla a Lista</Eyebrow></PopoverTitle>
            <Missing items={missing} />
          </PopoverContent>
        </Popover>
        {status}
      </div>
      <div className="flex w-full items-center justify-between gap-2 lg:max-w-[1040px]">
        <span className="hidden lg:flex">{status}</span>
        <div className="flex w-full items-center gap-2 lg:w-auto lg:gap-1.5">
          <a href={discardUrl} className="flex flex-1 justify-center rounded-lg bg-card p-2.5 text-sm text-foreground shadow-[0_0_0_1px_var(--border)] lg:flex-none lg:bg-transparent lg:px-3 lg:py-2 lg:shadow-none lg:hover:bg-muted">Descartar</a>
          <button
            type="submit"
            disabled={processing}
            aria-keyshortcuts="Meta+S Control+S"
            className="flex flex-[2] items-center justify-center gap-2.5 rounded-lg bg-primary p-2.5 text-sm text-primary-foreground hover:opacity-90 disabled:opacity-60 lg:flex-none lg:rounded-[7px] lg:px-3.5 lg:py-2"
          >
            Guardar<span aria-hidden="true" className="hidden lg:inline"><Kbd tone="ink" className="border-0 px-0">{isApple ? "⌘S" : "Ctrl S"}</Kbd></span>
          </button>
        </div>
      </div>
    </div>
  )
}
