import {
  TriggerMenu,
  TriggerMenuContent,
  type TriggerMenuDataItem,
  TriggerMenuInput,
  TriggerMenuItem,
  TriggerMenuItemIcon,
  TriggerMenuList,
  type TriggerMenuSelectDetails,
  TriggerMenuStatus,
} from "@ui-sdk/react/trigger-menu"
import { type ClipboardEvent, type DragEvent, type FocusEvent, type KeyboardEvent, type ReactNode, useRef, useState } from "react"
import { cx } from "./cx"
import { Eyebrow } from "./eyebrow"
import { Icon, type IconName } from "./icons"
import { Kbd } from "./kbd"

// Escribir de seguido (MT-118, Paper «v1 · 9 · Editar», columna «Escribir»): un textarea donde `/` abre los
// comandos del editor, `@` busca y enlaza historias, decisiones y capacidades, y pegar (⌘V) o arrastrar un archivo
// lo sube como adjunto y deja su referencia por nombre, `![captura.png](attachment:captura.png)` (MT-96, MT-122).
// El menú es el Trigger Menu de UI SDK (se abre en el cursor, filtra y lo elegido entra en el texto, con deshacer).

// Un comando de `/`: inserta texto donde estaba (`text`, con el cursor `back` caracteres antes del final; `block`, en
// su propia línea), elige un archivo para subirlo (`file`) o hace algo (`run`) tras borrar lo escrito. `hint`, a la derecha.
export type WritingCommand = { value: string; label: string; icon: IconName; hint?: string; text?: string; back?: number; block?: boolean; file?: boolean; run?: () => void }
// Algo que `@` puede enlazar: `ref` (MT-12, D-54) o vacío en las capacidades, que se citan por su título.
export type WritingLink = { value: string; ref: string; title: string; kind: "story" | "decision" | "capability"; url: string }

const LINK_ICONS: Record<WritingLink["kind"], IconName> = { story: "stories", decision: "decision", capability: "file" }
const LINK_KINDS: Record<WritingLink["kind"], string> = { story: "Historia", decision: "Decisión", capability: "Capacidad" }
// `@` busca entre todo el producto: solo los primeros que coinciden, para que la lista no sea un muro.
const LINKS_SHOWN = 8

// El markdown que deja `@`: el enlace con la referencia (o el título de la capacidad) como texto.
export const linkMarkdown = (link: WritingLink) => `[${(link.ref || link.title).replace(/[[\]]/g, "")}](${link.url})`

// Escribe en el textarea como si se tecleara (deshacer y onChange de React incluidos); si el navegador no deja, a mano.
export function insertText(area: HTMLTextAreaElement, start: number, end: number, text: string) {
  area.focus()
  area.setSelectionRange(start, end)
  if (document.execCommand("insertText", false, text)) return
  area.setRangeText(text, start, end, "end")
  area.dispatchEvent(new InputEvent("input", { bubbles: true, inputType: "insertText", data: text }))
}

// Sube un archivo como adjunto de la historia y devuelve su referencia por nombre.
export async function uploadAttachment(url: string, file: File): Promise<string> {
  const data = new FormData()
  data.append("file", file)
  const token = document.querySelector<HTMLMetaElement>("meta[name=csrf-token]")?.content ?? ""
  const response = await fetch(url, { method: "POST", body: data, headers: { Accept: "application/json", "X-CSRF-Token": token } })
  const json = (await response.json().catch(() => ({}))) as { reference?: string; error?: string }
  if (!response.ok || !json.reference) throw new Error(json.error ?? `No se pudo subir ${file.name}.`)
  return json.reference
}

type Props = {
  value: string
  onChange: (value: string) => void
  commands: WritingCommand[]
  links: WritingLink[]
  attachmentsUrl: string
  areaRef?: (area: HTMLTextAreaElement | null) => void
  id?: string
  "aria-label"?: string
  placeholder?: string
  rows?: number
  className?: string
  onKeyDown?: (event: KeyboardEvent<HTMLTextAreaElement>) => void
  onFocus?: (event: FocusEvent<HTMLTextAreaElement>) => void
  onBlur?: (event: FocusEvent<HTMLTextAreaElement>) => void
}

export function WritingField({ value, onChange, commands, links, attachmentsUrl, areaRef, className, ...props }: Props) {
  const area = useRef<HTMLTextAreaElement | null>(null)
  const picker = useRef<HTMLInputElement | null>(null)
  const pickAt = useRef(0)
  const [uploads, setUploads] = useState<string[]>([])
  const [error, setError] = useState<string | null>(null)

  // Lo que se pega o se suelta se sube y entra donde estaba el cursor, cada archivo en su línea.
  const upload = async (files: File[], at: number) => {
    const target = area.current
    if (!target || files.length === 0) return
    setError(null)
    setUploads((current) => [...current, ...files.map((file) => file.name)])
    let caret = at
    for (const file of files) {
      try {
        const reference = await uploadAttachment(attachmentsUrl, file)
        const before = target.value.slice(0, caret)
        const after = target.value.slice(caret)
        const text = `${before && !before.endsWith("\n") ? "\n" : ""}${reference}${after && !after.startsWith("\n") ? "\n" : ""}`
        insertText(target, caret, caret, text)
        caret += text.length
      } catch (failure) {
        setError(failure instanceof Error ? failure.message : `No se pudo subir ${file.name}.`)
      } finally {
        setUploads((current) => { const index = current.indexOf(file.name); return current.filter((_, i) => i !== index) })
      }
    }
  }
  const onPaste = (event: ClipboardEvent<HTMLTextAreaElement>) => {
    const files = Array.from(event.clipboardData.files)
    if (files.length === 0) return
    event.preventDefault()
    void upload(files, event.currentTarget.selectionEnd)
  }
  const onDrop = (event: DragEvent<HTMLTextAreaElement>) => {
    const files = Array.from(event.dataTransfer.files)
    if (files.length === 0) return
    event.preventDefault()
    void upload(files, event.currentTarget.selectionEnd)
  }

  const commandItems = commands.map((command) => ({ value: command.value, label: command.label }))
  const linkItems = links.map((link) => ({ value: link.value, label: `${link.ref} ${link.title}`.trim(), keywords: [LINK_KINDS[link.kind]] }))

  const choose = (value: string, details: TriggerMenuSelectDetails) => {
    const target = area.current
    if (details.trigger === "@") {
      const link = links.find((item) => item.value === value)
      if (link) details.insert(`${linkMarkdown(link)} `)
      return
    }
    const command = commands.find((item) => item.value === value)
    if (!command || !target) return
    if (command.text === undefined) {
      details.insert("")
      pickAt.current = details.match.start
      if (command.file) picker.current?.click()
      command.run?.()
      return
    }
    // Los bloques (casilla, código, sección) empiezan en su propia línea.
    const before = target.value.slice(0, details.match.start)
    const text = (command.block && before && !before.endsWith("\n") ? "\n" : "") + command.text
    details.insert(text)
    const back = command.back ?? 0
    if (back) requestAnimationFrame(() => { const caret = target.selectionEnd - back; target.setSelectionRange(caret, caret) })
  }

  return (
    <div className="flex flex-col gap-1.5">
      <TriggerMenu
        triggers={[
          { char: "/", items: commandItems },
          { char: "@", items: linkItems, spaces: 3 },
        ]}
        onSelect={choose}
      >
        <TriggerMenuInput
          {...props}
          ref={(node: HTMLTextAreaElement | null) => { area.current = node; areaRef?.(node) }}
          value={value}
          onChange={(event: React.ChangeEvent<HTMLTextAreaElement>) => onChange(event.currentTarget.value)}
          onPaste={onPaste}
          onDrop={onDrop}
          className={className}
        />
        <TriggerMenuStatus className="sr-only" />
        <TriggerMenuContent sideOffset={6} className="z-50 w-[320px] max-w-[calc(100vw-32px)] overflow-hidden rounded-xl border border-border bg-card p-1.5 text-foreground shadow-[0_12px_32px_rgba(15,15,17,0.14)]">
          <TriggerMenuList className="flex max-h-72 flex-col overflow-y-auto">
            {(state) => {
              const items = state.items as TriggerMenuDataItem[]
              if (state.trigger === "@") {
                return items.slice(0, LINKS_SHOWN).map((item) => {
                  const link = links.find((entry) => entry.value === item.value)
                  if (!link) return null
                  return (
                    <Row key={item.value} value={item.value} label={item.label ?? link.title} icon={LINK_ICONS[link.kind]}>
                      {link.ref && <span className="w-12 shrink-0 truncate font-mono text-label text-muted-foreground">{link.ref}</span>}
                      <span className="min-w-0 flex-1 truncate">{link.title}</span>
                      <span className="shrink-0 text-xs text-muted-foreground">{LINK_KINDS[link.kind]}</span>
                    </Row>
                  )
                })
              }
              return items.map((item) => {
                const command = commands.find((entry) => entry.value === item.value)
                if (!command) return null
                return (
                  <Row key={item.value} value={item.value} label={command.label} icon={command.icon}>
                    <span className="min-w-0 flex-1 truncate">{command.label}</span>
                    {command.hint && <span className="shrink-0 text-xs text-muted-foreground">{command.hint}</span>}
                  </Row>
                )
              })
            }}
          </TriggerMenuList>
        </TriggerMenuContent>
      </TriggerMenu>
      <input
        ref={picker}
        type="file"
        accept="image/*"
        multiple
        hidden
        tabIndex={-1}
        aria-hidden="true"
        onChange={(event) => {
          const files = Array.from(event.currentTarget.files ?? [])
          event.currentTarget.value = ""
          void upload(files, pickAt.current)
        }}
      />
      {(uploads.length > 0 || error) && (
        <p role="status" className={cx("text-xs", error ? "text-destructive" : "text-muted-foreground")}>
          {error ?? `Subiendo ${uploads.join(", ")}…`}
        </p>
      )}
    </div>
  )
}

function Row({ value, label, icon, children }: { value: string; label: string; icon: IconName; children: ReactNode }) {
  return (
    <TriggerMenuItem value={value} label={label} className="flex h-9 cursor-default items-center gap-2.5 rounded-md px-2.5 text-sm data-highlighted:bg-muted">
      <TriggerMenuItemIcon className="flex shrink-0 text-muted-foreground"><Icon name={icon} size={14} /></TriggerMenuItemIcon>
      {children}
    </TriggerMenuItem>
  )
}

// La columna «Escribir» (Paper MV7): las tres ayudas con su tecla.
export function WritingHints({ isApple }: { isApple: boolean }) {
  const hints = [
    { label: "Comandos", key: "/" },
    { label: "Enlazar historia o decisión", key: "@" },
    { label: "Pegar captura", key: isApple ? "⌘V" : "Ctrl V" },
  ]
  return (
    <section aria-labelledby="escribir" className="flex flex-col gap-2.5">
      <h2 id="escribir" className="contents"><Eyebrow className="leading-[14px] tracking-[0.1em]">Escribir</Eyebrow></h2>
      <ul className="flex flex-col gap-[7px]">
        {hints.map((hint) => (
          <li key={hint.label} className="flex items-center justify-between text-xs leading-4 text-muted-foreground">
            {hint.label}<Kbd className="px-[5px] text-muted-foreground">{hint.key}</Kbd>
          </li>
        ))}
      </ul>
    </section>
  )
}
