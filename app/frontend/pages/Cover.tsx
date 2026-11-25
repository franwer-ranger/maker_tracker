import { Link, usePage } from "@inertiajs/react"
import { useEffect, useRef, useState } from "react"
import { cx } from "@/components/ui/cx"
import { Section } from "@/components/ui/section"
import { AppShell } from "@/layouts/app-shell"
import { ago } from "@/lib/time"

type Capability = { slug: string; title: string; summary: string | null; changing: boolean }
type Story = { ref: string; title: string; actor: string | null; milestone: string | null; since: string; url: string }
type Activity = { id: number; actor: string; agent: boolean; text: string; at: string }

type CoverProps = {
  vision: string | null
  principles: string[]
  out_of_scope: string[]
  capabilities: { area: string; items: Capability[] }[]
  now: { code: string; title: string; goal: string; status: string; done: number; total: number; edit_url: string } | null
  changing: Story[]
  recent: Activity[]
  agents: { name: string; writing: boolean; target: string | null }[]
}

// Portada del proyecto (MT-88 · «v1 · 2 · Producto · Portada»): qué es el producto en una pantalla,
// sus capacidades por áreas y lo que está cambiando. `cover` es una live prop: se repinta sola.
export default function Cover({ cover }: { cover: CoverProps }) {
  const { project } = usePage().props
  const fresh = useFresh(cover.recent.map((event) => event.id))
  useTick(30_000)

  return (
    <AppShell title={project.name} active="product" crumbs={[{ label: project.name }, { label: "Producto" }]}>
      <div className="mx-auto flex max-w-[1120px] flex-col gap-12 px-6 py-10 lg:flex-row lg:gap-16 lg:px-12 lg:py-14">
        <div className="flex min-w-0 flex-1 flex-col gap-12">
          <header className="flex flex-col gap-5">
            <div className="flex items-center gap-3">
              <span className="flex size-9 items-center justify-center rounded-lg bg-foreground font-mono text-control font-medium text-background">{project.key}</span>
              <span className="text-sm font-medium text-foreground">{project.name}</span>
              <AgentsAtWork agents={cover.agents} />
            </div>
            <h1 className="max-w-[24ch] font-display text-[44px] leading-[1.05] tracking-[-0.015em] text-foreground text-balance">
              {cover.vision ?? "Sin visión todavía: escríbela en el brief."}
            </h1>
          </header>

          <Section index="01" title="Qué permite hacer">
            {cover.capabilities.length === 0 ? (
              <p className="text-sm text-muted-foreground">Sin capacidades documentadas. Un agente las crea con <code className="font-mono">mt doc create</code>.</p>
            ) : (
              <div className="flex flex-col gap-6">
                {cover.capabilities.map(({ area, items }) => (
                  <div key={area} className="flex flex-col gap-2">
                    <h3 className="text-control font-medium text-muted-foreground">{area}</h3>
                    <ul className="grid gap-3 sm:grid-cols-2">
                      {items.map((capability) => (
                        <li key={capability.slug} id={`capacidad-${capability.slug}`} className="flex scroll-mt-6 flex-col gap-1 rounded-xl border border-border bg-card p-4 target:border-foreground">
                          <div className="flex items-center justify-between gap-2">
                            <span className="text-sm font-medium text-foreground">{capability.title}</span>
                            {capability.changing && (
                              <span className="flex items-center gap-1.5 font-mono text-label text-signal">
                                <span className="size-1.5 rounded-full bg-signal" aria-hidden="true" />cambiando
                              </span>
                            )}
                          </div>
                          {capability.summary && <p className="text-control text-muted-foreground">{capability.summary}</p>}
                        </li>
                      ))}
                    </ul>
                  </div>
                ))}
              </div>
            )}
          </Section>

          {cover.now && (
            <Section
              index="02"
              title="Ahora"
              aside={
                <Link href={cover.now.edit_url} className="rounded-sm text-control text-muted-foreground hover:text-foreground">
                  Editar hito
                </Link>
              }
            >
              <div className="flex flex-col gap-3">
                <p className="font-mono text-label uppercase tracking-label text-muted-foreground">
                  {cover.now.code} · {cover.now.status} · {cover.now.done}/{cover.now.total}
                </p>
                <h3 className="text-xl font-semibold text-foreground">{cover.now.title}</h3>
                {cover.now.goal && <p className="max-w-[60ch] text-sm leading-6 text-body">{cover.now.goal}</p>}
                <div
                  role="progressbar"
                  aria-label={`Progreso de ${cover.now.code}`}
                  aria-valuemin={0}
                  aria-valuemax={cover.now.total}
                  aria-valuenow={cover.now.done}
                  className="h-1 w-full max-w-md overflow-hidden rounded-full bg-muted"
                >
                  <div className="h-full bg-foreground transition-[width] duration-500" style={{ width: `${cover.now.total ? (cover.now.done / cover.now.total) * 100 : 0}%` }} />
                </div>
              </div>
            </Section>
          )}

          <Section index="03" title="Qué está cambiando">
            {cover.changing.length === 0 ? (
              <p className="text-sm text-muted-foreground">Nada en curso.</p>
            ) : (
              <ul className="flex flex-col">
                {cover.changing.map((story) => (
                  <li key={story.ref}>
                    <a href={story.url} className="flex h-11 items-center gap-3 rounded-md px-2 -mx-2 text-sm hover:bg-muted">
                      <span className="size-1.5 shrink-0 rounded-full bg-signal agent-pulse" aria-hidden="true" />
                      <span className="w-14 shrink-0 font-mono text-control text-muted-foreground">{story.ref}</span>
                      <span className="min-w-0 flex-1 truncate text-foreground">{story.title}</span>
                      <span className="shrink-0 font-mono text-label text-muted-foreground">
                        {[story.actor, story.milestone, ago(story.since)].filter(Boolean).join(" · ")}
                      </span>
                    </a>
                  </li>
                ))}
              </ul>
            )}
          </Section>

          <div className="grid gap-12 sm:grid-cols-2">
            <Section index="04" title="Principios">
              <List items={cover.principles} empty="Sin principios en el brief." />
            </Section>
            <Section index="05" title="Lo que no es">
              <List items={cover.out_of_scope} empty="Sin «Fuera de alcance» en el brief." />
            </Section>
          </div>
        </div>

        <aside aria-labelledby="ultimo-titulo" className="flex shrink-0 flex-col gap-4 lg:w-72">
          <h2 id="ultimo-titulo" className="border-b border-border pb-2 font-mono text-label uppercase tracking-label text-muted-foreground">Lo último</h2>
          <ol aria-live="polite" className="flex flex-col">
            {cover.recent.map((event) => (
              <li key={event.id} className={cx("-mx-2 flex flex-col gap-0.5 rounded-md px-2 py-2", fresh.has(event.id) && "fresh")}>
                <span className={cx("font-mono text-label", event.agent ? "text-foreground" : "text-muted-foreground")}>
                  {event.actor} · {ago(event.at)}
                </span>
                <span className="text-control text-body">{event.text}</span>
              </li>
            ))}
          </ol>
          <p className="font-mono text-label text-muted-foreground">En directo: lo que hace un agente con <span className="text-foreground">mt</span> aparece aquí sin recargar.</p>
        </aside>
      </div>
    </AppShell>
  )
}

function List({ items, empty }: { items: string[]; empty: string }) {
  if (items.length === 0) return <p className="text-sm text-muted-foreground">{empty}</p>
  return (
    <ul className="flex flex-col gap-2.5">
      {items.map((item) => (
        <li key={item} className="text-sm leading-6 text-body">{item}</li>
      ))}
    </ul>
  )
}

// Vida del agente: el naranja solo aquí, mientras alguien trabaja (se apaga a los 60 s, Presence).
function AgentsAtWork({ agents }: { agents: CoverProps["agents"] }) {
  if (agents.length === 0) return null
  return (
    <span className="ml-auto flex items-center gap-2 font-mono text-label text-signal">
      <span className="size-1.5 rounded-full bg-signal agent-pulse" aria-hidden="true" />
      {agents.map((agent) => `${agent.name} ${agent.writing ? "escribiendo" : "leyendo"}${agent.target ? ` ${agent.target}` : ""}`).join(" · ")}
    </span>
  )
}

// Lo que entra con una recarga en directo se resalta un momento (no en la primera carga).
function useFresh(ids: number[]) {
  const seen = useRef<Set<number> | null>(null)
  const [fresh, setFresh] = useState<Set<number>>(new Set())
  const key = ids.join(",")
  useEffect(() => {
    if (seen.current) setFresh(new Set(ids.filter((id) => !seen.current!.has(id))))
    seen.current = new Set(ids)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [key])
  return fresh
}

// Para que «hace 3 min» no se quede quieto.
function useTick(ms: number) {
  const [, setNow] = useState(0)
  useEffect(() => {
    const id = setInterval(() => setNow(Date.now()), ms)
    return () => clearInterval(id)
  }, [ms])
}
