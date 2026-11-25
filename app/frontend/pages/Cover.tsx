import { Link, usePage } from "@inertiajs/react"
import { useEffect, useState } from "react"
import { CopyForAgent } from "@/components/ui/copy-for-agent"
import { cx } from "@/components/ui/cx"
import { EmptyState } from "@/components/ui/empty-state"
import { Icon, iconFor } from "@/components/ui/icons"
import { ProductMark } from "@/components/ui/product-combo"
import { AppShell } from "@/layouts/app-shell"
import { ago } from "@/lib/time"

// `changing`: "now" si un agente la está tocando ahora (el único naranja), "open" si la cambia una historia abierta.
type Capability = { slug: string; title: string; icon: string | null; url: string; summary: string | null; changing: "now" | "open" | null }
type Story = { ref: string; title: string; capabilities: string[]; agent: string | null; url: string }

type CoverProps = {
  empty: boolean
  logo: string | null
  status: { pending: number; at: string | null; by: string | null }
  vision: string | null
  screenshots: { url: string; name: string }[]
  capabilities: { area: string; items: Capability[] }[]
  capability_count: number
  principles: string[]
  out_of_scope: string[]
  now: { code: string; title: string; done: number; total: number; next: string | null } | null
  changing: Story[]
  context: string
  brief_url: string
  markdown_url: string
}

// Portada del producto (MT-102 · «v1 · 2 · Producto · Portada»): qué es el producto en una pantalla, sus
// capacidades por áreas y lo que está cambiando. `cover` es una live prop: se repinta sola.
export default function Cover({ cover }: { cover: CoverProps }) {
  const { project } = usePage().props
  useTick(30_000)

  const actions = (
    <>
      <DocStatus status={cover.status} />
      <CopyForAgent text={cover.context} shortcut="mod+shift+c" />
      <a href={cover.markdown_url} className="inline-flex h-8 items-center gap-2 rounded-md px-2 text-control text-muted-foreground hover:text-foreground">
        <Icon name="file" size={14} />Markdown
      </a>
    </>
  )

  if (cover.empty) {
    return (
      <AppShell title={project.name} active="product" crumbs={[{ label: project.name }, { label: "Producto" }]} copy={cover.context} actions={actions} ownMobileBar>
        <div className="flex flex-1 items-center justify-center px-5 py-11">
          <EmptyState
            figure="book"
            title="Todavía no hay nada escrito"
            actions={
              <>
                <a href={cover.brief_url} className="inline-flex h-8 items-center rounded-md bg-primary px-3.5 text-sm text-primary-foreground hover:opacity-90">Escribir el brief</a>
                <CopyForAgent text={cover.context} />
              </>
            }
          >
            Empieza por el brief: qué es, para quién y qué problema resuelve. Lo demás se va escribiendo al cerrar historias.
          </EmptyState>
        </div>
      </AppShell>
    )
  }

  return (
    <AppShell title={project.name} active="product" crumbs={[{ label: project.name }, { label: "Producto" }]} copy={cover.context} actions={actions} ownMobileBar>
      {/* Móvil: «Producto» y el estado de la documentación, como en Paper. */}
      <div className="flex h-12 shrink-0 items-center justify-between border-b border-border px-5 text-control text-foreground md:hidden">
        Producto
        <DocStatus status={cover.status} short />
      </div>

      <header className="flex flex-col gap-6 border-b border-border px-6 pt-8 pb-6 lg:flex-row lg:items-center lg:justify-between lg:gap-8 lg:px-8 lg:pt-[26px] lg:pb-[22px]">
        <div className="flex max-w-[600px] flex-col gap-3.5">
          <div className="flex items-center gap-3.5">
            <span className="hidden md:inline-flex"><ProductMark code={project.key} logo={cover.logo} size={44} /></span>
            <h1 className="font-display text-[44px] leading-[1.05] text-foreground md:text-[56px] md:leading-[56px]">{project.name}</h1>
          </div>
          {cover.vision ? (
            <p className="text-lg leading-[26px] tracking-[-0.01em] text-foreground md:text-xl md:leading-7"><Emphasis text={cover.vision} /></p>
          ) : (
            <p className="text-sm text-muted-foreground">Sin visión todavía: escríbela en el brief.</p>
          )}
        </div>
        {cover.screenshots.length > 0 && <Screenshots items={cover.screenshots} />}
      </header>

      <div className="grid flex-1 lg:grid-cols-[1fr_320px]">
        <div className="order-2 flex min-w-0 flex-col gap-[18px] px-5 py-5 lg:order-1 lg:px-8">
          <section aria-labelledby="capacidades" className="flex flex-col gap-[18px]">
            <div className="flex items-baseline justify-between gap-3">
              <h2 id="capacidades" className="text-[15px] leading-[18px] font-semibold text-foreground">Qué permite hacer</h2>
              {cover.capability_count > 0 && (
                <span className="text-xs text-muted-foreground">
                  <span className="font-mono">{cover.capability_count}</span><span className="hidden sm:inline"> {cover.capability_count === 1 ? "capacidad" : "capacidades"}</span>
                </span>
              )}
            </div>
            {cover.capabilities.length === 0 ? (
              <p className="text-sm text-muted-foreground">Sin capacidades documentadas. Un agente las crea con <code className="font-mono">mt doc create</code>.</p>
            ) : (
              <div className="grid gap-[18px] sm:grid-cols-2 xl:grid-cols-4">
                {cover.capabilities.map(({ area, items }) => (
                  <div key={area} className="flex min-w-0 flex-col gap-0.5">
                    <h3 className="pb-1.5 font-mono text-[10px] leading-3 tracking-[0.12em] text-muted-foreground uppercase">{area}</h3>
                    <ul className="flex flex-col">
                      {items.map((capability) => <CapabilityRow key={capability.slug} capability={capability} />)}
                    </ul>
                  </div>
                ))}
              </div>
            )}
          </section>

          <div className="grid gap-7 pt-1.5 lg:grid-cols-[1.4fr_1fr]">
            {cover.principles.length > 0 && (
              <section aria-labelledby="principios" className="flex flex-col gap-2.5">
                <h2 id="principios" className="text-[15px] leading-[18px] font-semibold text-foreground">Principios</h2>
                <ol className="grid gap-x-5 sm:grid-cols-2">
                  {cover.principles.map((principle, index) => (
                    <li key={principle} className="flex items-baseline gap-2.5 border-t border-border py-2">
                      <span className="w-[18px] shrink-0 font-mono text-label text-muted-foreground">{String(index + 1).padStart(2, "0")}</span>
                      <span className="text-sm leading-[18px] text-foreground">{principle}</span>
                    </li>
                  ))}
                </ol>
              </section>
            )}
            {cover.out_of_scope.length > 0 && (
              <section aria-labelledby="no-es" className="flex flex-col gap-2.5">
                <h2 id="no-es" className="text-[15px] leading-[18px] font-semibold text-foreground">Lo que no es</h2>
                <ul className="flex flex-wrap gap-2">
                  {cover.out_of_scope.map((item) => (
                    <li key={item} className="flex items-center gap-2 text-control text-muted-foreground">
                      <s className="decoration-1">{item}</s>
                      <span aria-hidden="true" className="text-border">·</span>
                    </li>
                  ))}
                </ul>
              </section>
            )}
          </div>
        </div>

        <aside className="order-1 flex flex-col gap-3.5 px-5 pt-5 lg:order-2 lg:border-l lg:border-border lg:px-6 lg:py-5">
          {cover.now && <Now now={cover.now} />}
          <section aria-labelledby="cambiando" className="hidden flex-col gap-3.5 lg:flex">
            <h2 id="cambiando" className="text-[15px] leading-[18px] font-semibold text-foreground">Qué está cambiando</h2>
            <Changing stories={cover.changing} />
          </section>
        </aside>

        {/* En móvil, «Qué está cambiando» va después de las capacidades. */}
        <section aria-labelledby="cambiando-movil" className="order-3 flex flex-col gap-3.5 border-t border-border px-5 py-5 lg:hidden">
          <h2 id="cambiando-movil" className="text-[15px] leading-[18px] font-semibold text-foreground">Qué está cambiando</h2>
          <Changing stories={cover.changing} />
        </section>
      </div>
    </AppShell>
  )
}

// «Al día · hace 2 días por claude», o cuántas historias Hechas faltan por documentar (MT-91).
function DocStatus({ status, short = false }: { status: CoverProps["status"]; short?: boolean }) {
  const pending = status.pending > 0
  return (
    <span className={cx("flex items-center gap-[7px] text-control text-muted-foreground", !short && "mr-2")}>
      <span aria-hidden="true" className={cx("size-1.5 shrink-0 rounded-full", pending ? "bg-state-defining" : "bg-success")} />
      <span>
        {pending ? `${status.pending} sin documentar` : "Al día"}
        {!short && status.at && ` · ${ago(status.at)}`}
        {!short && status.at && status.by && <> por <span className="font-mono">{status.by}</span></>}
      </span>
    </span>
  )
}

// `*así*` en la visión se pinta en Instrument Serif cursiva, como en Paper.
function Emphasis({ text }: { text: string }) {
  return text.split(/(\*[^*]+\*|_[^_]+_)/).map((part, index) =>
    /^(\*[^*]+\*|_[^_]+_)$/.test(part) ? (
      <em key={index} className="font-display text-[1.15em] tracking-[-0.01em]">{part.slice(1, -1)}</em>
    ) : (
      part
    ),
  )
}

// Las pantallas del producto: las imágenes adjuntas a la portada (MT-96), giradas como en Paper.
const tilts = ["-rotate-6", "rotate-3", "-rotate-2"]
function Screenshots({ items }: { items: CoverProps["screenshots"] }) {
  return (
    <div className="flex items-center justify-center pr-2.5">
      {items.map((shot, index) => (
        <div key={shot.url} className={cx("shrink-0 rounded-2xl border border-border bg-card p-1 shadow-[0_10px_24px_rgb(17_17_17/0.12)]", tilts[index], index > 0 && "-ml-[30px]")}>
          <img src={shot.url} alt={shot.name} className="h-[220px] w-[102px] rounded-xl object-cover md:h-[255px] md:w-[118px]" />
        </div>
      ))}
    </div>
  )
}

function CapabilityRow({ capability }: { capability: Capability }) {
  const now = capability.changing === "now"
  return (
    <li id={`capacidad-${capability.slug}`} className="scroll-mt-6">
      <Link
        href={capability.url}
        className={cx(
          "group flex items-start gap-2.5 border-t border-border py-[9px]",
          now && "-mx-1.5 rounded-lg border border-signal px-1.5",
        )}
      >
      <span className="flex size-[30px] shrink-0 items-center justify-center rounded-lg border border-border bg-card text-foreground">
        <Icon name={iconFor(capability.icon)} />
      </span>
      <span className="flex min-w-0 flex-1 flex-col gap-px">
        <span className="flex items-center gap-1.5">
          <span className="text-sm leading-[18px] font-medium text-foreground group-hover:underline group-hover:underline-offset-2">{capability.title}</span>
          {capability.changing && (
            <span
              title={now ? "Un agente la está cambiando ahora" : "La cambia una historia abierta"}
              className={cx("size-1.5 shrink-0 rounded-full border-[1.5px] border-dashed", now ? "border-signal" : "border-muted-foreground/60")}
            />
          )}
        </span>
        {capability.summary && <span className="line-clamp-2 text-xs leading-4 text-muted-foreground">{capability.summary}</span>}
      </span>
      <Icon name="chevronRight" size={14} className="mt-2 shrink-0 text-muted-foreground sm:hidden" />
      </Link>
    </li>
  )
}

function Now({ now }: { now: NonNullable<CoverProps["now"]> }) {
  const percent = now.total ? (now.done / now.total) * 100 : 0
  return (
    <div className="flex flex-col gap-2 rounded-[10px] border border-border bg-card p-3.5">
      <span className="font-mono text-[10px] leading-3 tracking-[0.12em] text-muted-foreground uppercase">Ahora</span>
      <span className="text-base leading-[21px] font-medium text-foreground">{now.title}</span>
      <div
        role="progressbar"
        aria-label={`Progreso de ${now.code}`}
        aria-valuemin={0}
        aria-valuemax={now.total}
        aria-valuenow={now.done}
        className="h-1 overflow-hidden rounded-[2px] bg-border"
      >
        <div className="h-full bg-foreground transition-[width] duration-500" style={{ width: `${percent}%` }} />
      </div>
      <span className="text-xs text-muted-foreground">
        <span className="font-mono">{now.done}</span> de <span className="font-mono">{now.total}</span> historias hechas
        {now.next && <> · sigue <span className="font-mono">{now.next}</span></>}
      </span>
    </div>
  )
}

function Changing({ stories }: { stories: Story[] }) {
  if (stories.length === 0) return <p className="text-sm text-muted-foreground">Ninguna historia abierta cambia el producto ahora.</p>
  return (
    <ol className="flex flex-col">
      {stories.map((story, index) => (
        <li key={story.ref} className="flex gap-3">
          <span className="flex flex-col items-center">
            <span aria-hidden="true" className={cx("mt-[3px] size-[11px] shrink-0 rounded-full border-2 border-dashed", story.agent ? "border-signal" : "border-muted-foreground/60")} />
            {index < stories.length - 1 && <span aria-hidden="true" className="w-px grow bg-border" />}
          </span>
          <a href={story.url} className="flex flex-col gap-0.5 pb-3 hover:underline-offset-2">
            <span className="text-sm leading-[19px] text-foreground">{story.title}</span>
            <span className="text-xs text-muted-foreground">
              {[...story.capabilities, story.ref].join(" · ")}
              {story.agent && <> · <span className="text-signal">{story.agent} trabajando ahora</span></>}
            </span>
          </a>
        </li>
      ))}
    </ol>
  )
}

// Para que «hace 3 min» no se quede quieto.
function useTick(ms: number) {
  const [, setNow] = useState(0)
  useEffect(() => {
    const id = setInterval(() => setNow(Date.now()), ms)
    return () => clearInterval(id)
  }, [ms])
}
