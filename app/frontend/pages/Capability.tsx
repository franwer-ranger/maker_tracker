import { Link, usePage } from "@inertiajs/react"
import type { ReactNode } from "react"
import { CopyForAgent } from "@/components/ui/copy-for-agent"
import { cx } from "@/components/ui/cx"
import { EmptyState } from "@/components/ui/empty-state"
import { Icon, iconFor } from "@/components/ui/icons"
import { InlineMarkdown } from "@/components/ui/inline-markdown"
import { PageHeader } from "@/components/ui/page-header"
import { Rules } from "@/components/ui/rules"
import { SideChange, SideDecision, SideSection } from "@/components/ui/side-column"
import { Walkthrough } from "@/components/ui/walkthrough"
import { AppShell } from "@/layouts/app-shell"

type Block =
  | { type: "paragraph" | "heading" | "code"; text: string }
  | { type: "list" | "ordered"; items: string[] }

type CapabilityProps = {
  slug: string
  title: string
  icon: string | null
  area: string | null
  kind: "capability" | "crosscutting"
  empty: boolean
  status: { pending: string[]; at: string | null; story: string | null }
  lead: string | null
  rules: { title: string; text: string | null; decisions: string[] }[] | null
  questions: { question: string; answer: string | null }[] | null
  sections: { title: string | null; blocks: Block[] }[]
  screens: { code: string; title: string; src: string }[]
  changes: { at: string; title: string; ref: string; actor: string; url: string }[]
  decisions: { reference: string; title: string; url: string }[]
  related: { slug: string; title: string; icon: string | null; url: string }[]
  copy: string
  edit: string
  markdown_url: string
}

const day = new Intl.DateTimeFormat("es", { day: "numeric", month: "short" })
const shortDate = (iso: string) => day.format(new Date(iso)).replace(".", "")

// La página de una capacidad (MT-103 · «v1 · 3 · Producto · Capacidad»): su documentación como página viva.
// Lo que no está escrito no se pinta. `capability` es una live prop: se repinta sola.
export default function Capability({ capability }: { capability: CapabilityProps }) {
  const { project, nav } = usePage().props
  const kindLabel = capability.kind === "crosscutting" ? "Transversal" : "Capacidad"
  const crumbs = [{ label: "Producto", href: nav.cover }, ...(capability.area ? [{ label: capability.area }] : []), { label: capability.title }]

  const actions = (
    <>
      <CopyForAgent text={capability.copy} shortcut="mod+shift+c" />
      <a href={capability.markdown_url} className="inline-flex h-8 items-center gap-2 rounded-md px-2 text-control text-muted-foreground hover:text-foreground">
        <Icon name="file" size={14} />Markdown
      </a>
      <CopyForAgent text={capability.edit} label="Editar" icon="pencil" shortcut="e" />
    </>
  )

  if (capability.empty) {
    return (
      <AppShell title={`${capability.title} · ${project.name}`} active="product" crumbs={crumbs} copy={capability.copy} actions={actions}>
        <div className="flex flex-1 items-center justify-center px-5 py-11">
          <EmptyState
            figure="page"
            title={`${capability.title} aún no está escrita`}
            actions={
              <>
                <CopyForAgent text={capability.edit} label="Escribirla" icon="pencil" className="border border-border bg-card px-3 text-foreground! hover:bg-muted" />
                <CopyForAgent text={capability.copy} />
              </>
            }
          >
            Se pone al día sola cuando se cierra una historia que la cambia. También puedes escribirla ahora.
          </EmptyState>
        </div>
      </AppShell>
    )
  }

  const side = (
    <>
      {capability.changes.length > 0 && (
        <SideSection title="Cómo ha cambiado" labelledBy="cambios">
          {capability.changes.map((change) => (
            <SideChange key={`${change.ref}-${change.at}`} date={shortDate(change.at)} title={change.title} refs={[change.ref, change.actor]} href={change.url} />
          ))}
        </SideSection>
      )}
      {capability.decisions.length > 0 && (
        <SideSection title="La rigen" labelledBy="la-rigen">
          {capability.decisions.map((decision) => <SideDecision key={decision.reference} reference={decision.reference} title={decision.title} href={decision.url} />)}
        </SideSection>
      )}
      {capability.related.length > 0 && (
        <SideSection title="Relacionadas" labelledBy="relacionadas">
          <ul className="flex flex-col gap-2">
            {capability.related.map((page) => (
              <li key={page.slug}>
                <Link href={page.url} className="flex items-center gap-2.5 text-control text-foreground hover:underline hover:underline-offset-2">
                  <span className="flex size-7 shrink-0 items-center justify-center rounded-[7px] bg-muted"><Icon name={iconFor(page.icon)} size={14} /></span>
                  {page.title}
                </Link>
              </li>
            ))}
          </ul>
        </SideSection>
      )}
    </>
  )

  return (
    <AppShell title={`${capability.title} · ${project.name}`} active="product" crumbs={crumbs} copy={capability.copy} actions={actions}>
      <div className="flex flex-col gap-10 px-5 pt-7 pb-10 lg:flex-row lg:items-start lg:gap-14 lg:pt-12 lg:pr-14 lg:pb-14 lg:pl-[72px]">
        <article className="flex min-w-0 flex-col gap-10 lg:w-[700px] lg:shrink">
          <PageHeader
            icon={iconFor(capability.icon)}
            eyebrow={[kindLabel, capability.area].filter(Boolean).join(" · ")}
            status={<Status status={capability.status} />}
            title={capability.title}
            lead={capability.lead && <InlineMarkdown text={capability.lead} />}
          />

          {capability.screens.length > 0 && (
            <Block title="El recorrido" aside="Pantallas de la app" gap="gap-[18px]">
              <div className="-mx-5 px-5 lg:mx-0 lg:px-0"><Walkthrough screens={capability.screens} /></div>
            </Block>
          )}

          {capability.rules && (
            <Block title="Cómo funciona">
              <Rules
                items={capability.rules.map((rule) => ({
                  title: <InlineMarkdown text={rule.title} />,
                  text: rule.text && <InlineMarkdown text={rule.text} />,
                  decision: rule.decisions.join(" · ") || undefined,
                }))}
              />
            </Block>
          )}

          {capability.questions && (
            <Block title="¿Qué pasa si…?">
              <ul className="flex flex-col">
                {capability.questions.map((item, index) => (
                  <li key={index} className="flex flex-col gap-1 border-t border-border py-3.5">
                    <span className="text-[15px] leading-[18px] font-medium text-foreground"><InlineMarkdown text={item.question} /></span>
                    {item.answer && <span className="text-sm leading-[21px] text-body"><InlineMarkdown text={item.answer} /></span>}
                  </li>
                ))}
              </ul>
            </Block>
          )}

          {capability.sections.map((section, index) => (
            <Block key={index} title={section.title}>
              <Prose blocks={section.blocks} />
            </Block>
          ))}

          <a href={capability.markdown_url} className="hidden self-start text-control text-foreground underline decoration-border underline-offset-[3px] hover:decoration-foreground lg:inline">
            Ver la documentación completa en markdown
          </a>
        </article>

        <aside aria-label="Contexto de la capacidad" className="flex flex-col gap-[30px] lg:w-[300px] lg:shrink-0 lg:pt-1.5">
          {side}
        </aside>

        <a href={capability.markdown_url} className="self-start text-control text-foreground underline decoration-border underline-offset-[3px] lg:hidden">
          Ver todo · documentación en markdown
        </a>
      </div>
    </AppShell>
  )
}

// «Al día · 23 nov, con PG-56»; si una historia Hecha la cambió sin actualizarla (MT-91), cuál.
function Status({ status }: { status: CapabilityProps["status"] }) {
  const pending = status.pending.length > 0
  if (!pending && !status.at) return null
  return (
    <span className="flex items-center gap-[7px] text-xs text-muted-foreground">
      <span aria-hidden="true" className={cx("size-1.5 shrink-0 rounded-full", pending ? "bg-state-defining" : "bg-success")} />
      {pending ? (
        <span>Sin actualizar con <span className="font-mono">{status.pending.join(", ")}</span></span>
      ) : (
        <span>
          Al día · {shortDate(status.at!)}
          {status.story && <span className="hidden sm:inline">, con <span className="font-mono">{status.story}</span></span>}
        </span>
      )}
    </span>
  )
}

function Block({ title, aside, gap = "gap-2", children }: { title: string | null; aside?: string; gap?: string; children: ReactNode }) {
  return (
    <section className={cx("flex flex-col", gap)}>
      {title && (
        <div className="flex items-baseline justify-between gap-4 pb-2">
          <h2 className="text-xl leading-6 font-medium tracking-[-0.01em] text-foreground"><InlineMarkdown text={title} /></h2>
          {aside && <span className="hidden text-control text-muted-foreground sm:inline">{aside}</span>}
        </div>
      )}
      {children}
    </section>
  )
}

// El resto del markdown, con las mismas piezas de texto.
function Prose({ blocks }: { blocks: Block[] }) {
  return (
    <div className="flex flex-col gap-3 text-sm leading-[21px] text-body">
      {blocks.map((block, index) => {
        switch (block.type) {
          case "heading":
            return <h3 key={index} className="pt-2 text-[15px] leading-[18px] font-medium text-foreground"><InlineMarkdown text={block.text} /></h3>
          case "code":
            return <pre key={index} className="overflow-x-auto rounded-md border border-border bg-card p-3 font-mono text-control text-foreground">{block.text}</pre>
          case "list":
          case "ordered": {
            const List = block.type === "ordered" ? "ol" : "ul"
            return (
              <List key={index} className="flex flex-col">
                {block.items.map((item, position) => (
                  <li key={position} className="flex gap-2.5 border-t border-border py-2.5">
                    <span aria-hidden="true" className="w-[18px] shrink-0 font-mono text-label leading-[21px] text-muted-foreground">
                      {block.type === "ordered" ? String(position + 1).padStart(2, "0") : "·"}
                    </span>
                    <span><InlineMarkdown text={item} /></span>
                  </li>
                ))}
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
