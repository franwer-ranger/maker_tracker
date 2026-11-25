import { type ReactNode, useState } from "react"
import { AgentWorking } from "@/components/ui/agent-working"
import { Button } from "@/components/ui/button"
import { Checklist } from "@/components/ui/checklist"
import { CopyForAgent } from "@/components/ui/copy-for-agent"
import { cx } from "@/components/ui/cx"
import { DotIllustration, figures, type Figure } from "@/components/ui/dot-illustration"
import { EmptyState } from "@/components/ui/empty-state"
import { Eyebrow } from "@/components/ui/eyebrow"
import { FocusSignal } from "@/components/ui/focus-signal"
import { Icon, type IconName } from "@/components/ui/icons"
import { Kbd } from "@/components/ui/kbd"
import { ListRow } from "@/components/ui/list-row"
import { OpenQuestion } from "@/components/ui/open-question"
import { PageHeader } from "@/components/ui/page-header"
import { ProductCombo } from "@/components/ui/product-combo"
import { ProductDiff } from "@/components/ui/product-diff"
import { Rules } from "@/components/ui/rules"
import { SideActivity, SideChange, SideDecision, SideSection } from "@/components/ui/side-column"
import { StateBadge, states, type StoryState } from "@/components/ui/state"
import { TaskTypeLabel, TaskTypeTile, taskTypes, type TaskType } from "@/components/ui/task-type"
import { TopBar } from "@/components/ui/top-bar"
import { Walkthrough } from "@/components/ui/walkthrough"
import { usePage } from "@inertiajs/react"
import { AppShell } from "@/layouts/app-shell"

// /design (MT-101): todas las piezas de la UI v1 (Paper «08», «10», «11» y «12»), en claro y en oscuro,
// para compararlas con Paper. Los textos de ejemplo son los de Paper (Postgram); no son datos de la BD.
export default function Design() {
  const { frame, project } = usePage().props
  const [mode, setMode] = useState<"light" | "dark" | "both">("both")

  return (
    <AppShell title="Sistema de diseño" crumbs={[{ label: project.name }, { label: "Sistema de diseño" }]} actions={<Segmented value={mode} onChange={setMode} />}>
      <div className={cx("grid gap-px bg-border", mode === "both" && "xl:grid-cols-2")}>
        {(mode === "both" ? (["light", "dark"] as const) : [mode]).map((theme) => (
          <div key={theme} className={cx(theme, "bg-background text-foreground")}>
            <Catalog theme={theme} products={frame.products} current={project.key} />
          </div>
        ))}
      </div>
    </AppShell>
  )
}

function Segmented({ value, onChange }: { value: "light" | "dark" | "both"; onChange: (value: "light" | "dark" | "both") => void }) {
  const options = [["light", "Claro"], ["dark", "Oscuro"], ["both", "Los dos"]] as const
  return (
    <div role="group" aria-label="Tema del catálogo" className="flex rounded-md border border-border p-0.5">
      {options.map(([key, label]) => (
        <button key={key} type="button" aria-pressed={value === key} onClick={() => onChange(key)} className={cx("rounded-sm px-2.5 py-1 text-control", value === key ? "bg-muted text-foreground" : "text-muted-foreground")}>
          {label}
        </button>
      ))}
    </div>
  )
}

function Card({ title, note, children }: { title: string; note?: string; children: ReactNode }) {
  return (
    <section className="flex flex-col gap-5 rounded-xl border border-border bg-card p-6">
      <div className="flex items-start justify-between gap-6">
        <Eyebrow className="text-foreground">{title}</Eyebrow>
        {note && <p className="max-w-[44ch] text-right text-control text-muted-foreground">{note}</p>}
      </div>
      {children}
    </section>
  )
}

const icons: IconName[] = ["taller", "product", "stories", "roadmap", "decision", "robot", "search", "copy", "check", "question", "pencil", "design", "spark", "pin", "swap", "contrast", "menu", "file", "vibrate", "arrowRight", "enter", "tab", "chevronDown", "chevronRight"]

function Catalog({ theme, products, current }: { theme: string; products: { key: string; name: string; url: string }[]; current: string }) {
  return (
    <div className="flex flex-col gap-6 px-7 py-10">
      <PageHeader eyebrow={`Sistema · v1 · ${theme === "dark" ? "oscuro" : "claro"}`} title="Componentes base" lead="Calma para trabajar, carácter en los momentos justos. Comportamiento de UI SDK, aspecto nuestro." />

      <Card title="Botones" note="Un solo botón en tinta por pantalla. El naranja nunca es un botón.">
        <div className="flex flex-wrap items-center gap-4">
          <Button shortcut="L">Marcar como Lista</Button>
          <Button variant="secondary">Escribirlos</Button>
          <Button variant="ghost">Ver historia</Button>
        </div>
      </Card>

      <Card title="Acción ligera · Copiar para tu agente" note="Secundaria y en muchos sitios. No invita a irse al chat.">
        <div className="flex"><CopyForAgent text="mt show PG-56" /></div>
      </Card>

      <Card title="Combo de producto" note="Dropdown con buscador (escala a muchos productos).">
        <div className="w-64"><ProductCombo products={products} current={current} tone="panel" /></div>
      </Card>

      <Card title="Mono · etiquetas, códigos y atajos" note="Geist Mono solo para lo que es dato.">
        <div className="flex flex-wrap items-center gap-5">
          <Eyebrow>Después, en el orden del roadmap</Eyebrow>
          <span className="font-mono text-control text-muted-foreground">MT-50 · M1 Ahora</span>
          <span className="font-mono text-base text-foreground">02</span>
          <Kbd>⌘K</Kbd><Kbd>L</Kbd><Kbd>⌘⇧C</Kbd>
        </div>
      </Card>

      <Card title="Tipo de tarea del taller" note="Icono descriptivo + nombre. Grande en lo primero, pequeño en la lista.">
        <div className="flex gap-3">{(Object.keys(taskTypes) as TaskType[]).map((type) => <TaskTypeTile key={type} type={type} />)}</div>
        <div className="flex flex-col gap-2">{(Object.keys(taskTypes) as TaskType[]).map((type) => <TaskTypeLabel key={type} type={type} />)}</div>
      </Card>

      <Card title="Estado de una historia" note="El color es estado, no adorno. Punto + nombre.">
        <div className="flex flex-wrap gap-2">{(Object.keys(states) as StoryState[]).map((state) => <StateBadge key={state} state={state} />)}</div>
      </Card>

      <Card title="Fila de lista" note="Número de orden, lo que es y por qué; a la derecha el tipo y una acción secundaria.">
        <ListRow index="04" title="mt milestone con un título que lleva punto falla" reason="Le faltan los criterios de aceptación." refs={["MT-77", "M1"]} type="criteria" action={<Button variant="secondary">Escribirlos</Button>} />
      </Card>

      <Card title="Vida · el agente trabajando" note="El único naranja que se mueve.">
        <div className="flex flex-wrap items-center gap-6">
          <AgentWorking agent="claude" target="PG-56" variant="chip" />
          <AgentWorking agent="claude" target="está editando esta historia · ahora" variant="inline" />
          <span className="rounded-md bg-sidebar px-3.5 py-2.5"><AgentWorking agent="claude" target="PG-56" /></span>
        </div>
      </Card>

      <Card title="Señal de enfoque" note="Naranja solo para atención.">
        <div className="flex flex-wrap items-center gap-6">
          <FocusSignal>Bloquea pasarla a Lista</FocusSignal>
          <FocusSignal soft>Te toca: responder la pregunta de PG-56</FocusSignal>
        </div>
      </Card>

      <Card title="Cabecera de página" note="Icono en casilla gris, eyebrow en mono, estado; título en Instrument Serif; entradilla.">
        <div className="rounded-lg bg-background p-5">
          <PageHeader icon="vibrate" eyebrow="Capacidad · Recibir" status={<StateBadge state="ready" />} title="Revelarlo" lead="Quien recibe una foto va al sitio y la revela agitando el móvil." />
        </div>
      </Card>

      <Card title="Barra superior" note="Migas a la izquierda; a la derecha solo acciones ligeras.">
        <div className="overflow-hidden rounded-lg border border-border bg-background">
          <TopBar crumbs={[{ label: "Producto", href: "#" }, { label: "Revelarlo" }]} actions={<><CopyForAgent text="mt doc show revelarlo" /><button type="button" className="inline-flex items-center gap-2 px-2 text-control text-muted-foreground"><Icon name="pencil" size={13} />Editar<Kbd className="border-0 px-0">E</Kbd></button></>} />
        </div>
      </Card>

      <Card title="Pregunta abierta" note="Borde completo, nunca raya lateral. Naranja solo en el punto de bloqueo.">
        <OpenQuestion
          question="¿Desde qué distancia cuenta como «cerca»?"
          context="Solo cuando ya estás llegando."
          blocks="Bloquea pasarla a Lista"
          options={[
            { value: "radio", label: "Cuando el círculo de error toca el radio", detail: "radio + precisión", recommended: true },
            { value: "fixed", label: "Un margen fijo", detail: "radio + 100 m" },
          ]}
        />
      </Card>

      <Card title="Diff del producto" note="Una capacidad por bloque. + lo que añade, = lo que no cambia.">
        <ProductDiff blocks={[{ capability: "Ir a buscarlo", icon: "pin", adds: ["Avisa si la ubicación es imprecisa."], keeps: ["La regla del radio no cambia (D-52)."] }]} />
      </Card>

      <Card title="Recorrido con pantallas" note="Capturas en orden, número en mono y flecha fina.">
        <Walkthrough screens={[{ code: "C1", title: "En tu montón" }, { code: "C2", title: "Vas a buscarla" }, { code: "C3", title: "Agitas" }]} />
      </Card>

      <Card title="Reglas y preguntas" note="La decisión que la respalda, a la derecha en mono.">
        <Rules items={[{ title: "Tienes que estar allí", text: "Con margen si el GPS no es preciso.", decision: "D-52" }, { title: "¿Y si la abro desde la web?", text: "Se revela igual, sin cuenta (D-35)." }]} />
      </Card>

      <Card title="Checklist y lista en línea" note="Criterios con casilla; lo secundario en una línea.">
        <Checklist items={[{ text: "Con lecturas imprecisas cerca, C2 avisa." }, { text: "Lejos del sitio, no cambia nada." }]} outOfScope={["Relajar el radio", "Mostrar los metros de error"]} more={{ label: "Contexto completo", href: "#" }} />
      </Card>

      <Card title="Columna lateral" note="Cambios, decisiones (sin «VIGENTE»), pantallas y actividad con robot.">
        <div className="flex max-w-sm flex-col gap-8">
          <SideSection title="Cómo ha cambiado"><SideChange date="23 nov" title="Avisa cuando la ubicación es imprecisa" refs={["PG-56", "claude"]} /></SideSection>
          <SideSection title="La rigen"><SideDecision reference="D-45" title="Revelar cuesta un pequeño esfuerzo" /></SideSection>
          <SideSection title="Pantallas"><Walkthrough screens={[{ code: "C2", title: "" }]} /></SideSection>
          <SideSection title="Actividad">
            <SideActivity actor="saul" agent text="la creó" when="17 nov" />
            <SideActivity actor="fran" text="respondió la pregunta" when="17 nov" />
          </SideSection>
        </div>
      </Card>

      <Card title="Iconos" note="Un set de línea, trazo 1.6, del color de su texto.">
        <div className="flex flex-wrap gap-4 text-foreground">{icons.map((name) => <span key={name} title={name}><Icon name={name} size={16} /></span>)}</div>
      </Card>

      <Card title="11 · Ilustraciones de puntos" note="Rejilla de 15×15: apagados en --border, encendidos en --body.">
        <div className="flex flex-wrap gap-9">
          {(Object.keys(figures) as Figure[]).map((figure) => (
            <span key={figure} className="flex flex-col items-center gap-2.5"><DotIllustration figure={figure} /><span className="font-mono text-label text-muted-foreground">{figure}</span></span>
          ))}
        </div>
      </Card>

      <Card title="12 · Estados vacíos" note="Centrados, con su ilustración. Un solo botón en tinta, y solo si es el primer paso.">
        <div className="grid gap-px overflow-hidden rounded-lg border border-border bg-border lg:grid-cols-2">
          <div className="bg-card"><EmptyState figure="book" title="Todavía no hay nada escrito" actions={<><Button>Escribir el brief</Button><CopyForAgent text="mt brief" /></>}>Empieza por el brief: qué es, para quién y qué problema resuelve. Lo demás se va escribiendo al cerrar historias.</EmptyState></div>
          <div className="bg-card"><EmptyState figure="calm" title="Nada que definir ahora" actions={<Button variant="secondary">Apuntar una idea</Button>}>Todo lo que viene en el roadmap está listo para construir. Buen momento para pensar en lo siguiente.</EmptyState></div>
          <div className="bg-card"><EmptyState figure="page" title="Revelarlo aún no está escrita" actions={<><Button variant="secondary">Escribirla</Button><CopyForAgent text="mt doc show revelarlo" /></>}>Se pone al día sola cuando se cierra una historia que la cambia. También puedes escribirla ahora.</EmptyState></div>
          <div className="bg-card"><EmptyState figure="flag" title="Sin hitos todavía" actions={<Button shortcut="H">Nuevo hito</Button>}>Un hito es un sitio al que quieres llegar, con las historias que hacen falta. Crea el primero.</EmptyState></div>
          <div className="bg-card"><EmptyState figure="cards" title="Aún no hay historias" actions={<Button shortcut="N">Apuntar una idea</Button>}>Una historia es un cambio en el producto. Empieza apuntando una idea; ya le pondrás hito.</EmptyState></div>
          <div className="bg-card"><EmptyState figure="search" title="Ninguna historia cambia «El marco»" actions={<Button variant="secondary">Quitar el filtro</Button>}>Quita el filtro para verlas todas.</EmptyState></div>
          <div className="bg-card"><EmptyState figure="fork" title="Ninguna decisión apuntada" actions={<Button variant="secondary">Nueva decisión</Button>} command="mt decide «…» --why «…»">Cuando decidas algo que no se debe olvidar, apúntalo con su porqué. Así no se vuelve a discutir.</EmptyState></div>
          <div className="bg-card"><EmptyState figure="spark" title="Sin ideas en la bandeja" actions={<Button variant="secondary">Apuntar una idea</Button>}>Lo que se te ocurra y aún no tenga sitio, apúntalo aquí.</EmptyState></div>
        </div>
      </Card>
    </div>
  )
}
