import { Link, useForm, usePage } from "@inertiajs/react"
import type { FormEvent } from "react"
import { Button } from "@/components/ui/button"
import { TextField } from "@/components/ui/field"
import { Kbd } from "@/components/ui/kbd"
import { AppShell } from "@/layouts/app-shell"

const isApple = /Mac|iPhone|iPad/.test(navigator.platform)

type Props = { milestone: { code: string; title: string; goal: string; version: number; url: string } }

// Editar el título y el objetivo de un hito (MT-99). Sin validación del navegador (noValidate):
// las reglas son las del modelo y Rails devuelve sus errores, que se pintan en cada campo.
export default function MilestoneEdit({ milestone }: Props) {
  const { nav } = usePage().props
  const form = useForm({ title: milestone.title, goal: milestone.goal, version: milestone.version })
  // `base`: el conflicto de versión (Versioned::Conflict), que no es de ningún campo.
  const base = (form.errors as Record<string, string | string[] | undefined>).base

  const submit = (event: FormEvent) => {
    event.preventDefault()
    form.transform((data) => ({ milestone: data }))
    form.patch(milestone.url, { preserveScroll: true })
  }

  return (
    <AppShell title={`Editar ${milestone.code}`}>
      <div className="mx-auto flex max-w-[640px] flex-col gap-8 px-6 py-10 lg:py-14">
        <header className="flex flex-col gap-2">
          <p className="font-mono text-label uppercase tracking-label text-muted-foreground">{milestone.code} · Editar hito</p>
          <h1 className="text-2xl font-semibold text-foreground">Título y objetivo</h1>
        </header>

        <form noValidate onSubmit={submit} aria-label={`Editar ${milestone.code}`} className="flex flex-col gap-6"
          onKeyDown={(event) => { if (event.key === "Enter" && (event.metaKey || event.ctrlKey)) submit(event) }}>
          {base && (
            <p role="alert" className="rounded-lg border border-signal/40 bg-card px-4 py-3 text-control text-foreground shadow-[inset_2px_0_0_var(--signal)]">
              {[base].flat().join(" ")}
            </p>
          )}
          <TextField label="Título" name="milestone[title]" value={form.data.title} onChange={(value) => form.setData("title", value)} errors={form.errors.title} />
          <TextField
            label="Objetivo"
            name="milestone[goal]"
            multiline
            value={form.data.goal}
            onChange={(value) => form.setData("goal", value)}
            description="Qué tiene que ser verdad al cerrar el hito, en una o dos frases."
            errors={form.errors.goal}
          />
          <div className="flex items-center gap-3 border-t border-border pt-5">
            <Button type="submit" disabled={form.processing} aria-keyshortcuts="Meta+Enter Control+Enter">
              Guardar <span aria-hidden="true"><Kbd className="bg-white/15 text-primary-foreground">{isApple ? "⌘↵" : "Ctrl ↵"}</Kbd></span>
            </Button>
            <Link href={nav.cover} className="rounded-md px-3 py-1.5 text-control text-muted-foreground hover:text-foreground">Cancelar</Link>
            <span className="ml-auto font-mono text-label text-muted-foreground">mt milestone edit {milestone.code}</span>
          </div>
        </form>
      </div>
    </AppShell>
  )
}
