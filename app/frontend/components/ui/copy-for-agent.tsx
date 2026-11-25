import { useShortcut, useShortcutHint } from "@ui-sdk/react/shortcuts"
import { useEffect, useState } from "react"
import { cx } from "./cx"
import { Icon } from "./icons"
import { Kbd } from "./kbd"

// «Copiar para tu agente» (08): acción ligera, nunca protagonista. Copia `text` y confirma unos segundos.
// `shortcut` (p. ej. "mod+shift+c") lo registra de verdad: solo en una instancia por pantalla.
// `iconOnly` para la cabecera móvil: solo el icono, con la etiqueta para lectores de pantalla.
// `shortLabel` en móvil (por debajo de `sm`) en lugar de `label`, para que quepa en la fila (p. ej. «Copiar las 5»).
export function CopyForAgent({ text, label = "Copiar para tu agente", shortLabel, shortcut = null, iconOnly = false, className }: { text: string; label?: string; shortLabel?: string; shortcut?: string | null; iconOnly?: boolean; className?: string }) {
  const [copied, setCopied] = useState(false)
  const hint = useShortcutHint(shortcut ?? "mod+shift+c")

  useEffect(() => {
    if (!copied) return
    const timer = setTimeout(() => setCopied(false), 2400)
    return () => clearTimeout(timer)
  }, [copied])

  const copy = async () => {
    try {
      await navigator.clipboard.writeText(text)
      setCopied(true)
    } catch {
      /* sin portapapeles: no se confirma lo que no ha pasado */
    }
  }

  useShortcut(shortcut, () => void copy(), { description: label })

  return (
    <button
      type="button"
      onClick={copy}
      aria-live="polite"
      aria-label={iconOnly ? (copied ? "Copiado" : label) : undefined}
      aria-keyshortcuts={shortcut ? hint.ariaKeyshortcuts : undefined}
      className={cx(
        "inline-flex h-8 items-center gap-2 rounded-md px-2 text-control whitespace-nowrap transition-colors",
        !iconOnly && (copied ? "bg-muted text-foreground" : "text-muted-foreground hover:text-foreground"),
        className,
      )}
    >
      <Icon name={copied ? "check" : "copy"} size={14} />
      {!iconOnly && (copied ? <Responsive short={shortLabel ? "Copiado" : undefined} full="Copiado · pégalo en Claude, Codex o el que uses" /> : <Responsive short={shortLabel} full={label} />)}
      {!iconOnly && !copied && shortcut && <Kbd className="border-0 px-0">{hint.text}</Kbd>}
    </button>
  )
}

function Responsive({ short, full }: { short?: string; full: string }) {
  if (!short) return full
  return (
    <>
      <span className="sm:hidden">{short}</span>
      <span className="hidden sm:inline">{full}</span>
    </>
  )
}
