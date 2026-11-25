import { useEffect, useState } from "react"
import { cx } from "./cx"
import { Icon } from "./icons"
import { Kbd } from "./kbd"

// «Copiar para tu agente» (08): acción ligera, nunca protagonista. Copia `text` y confirma unos segundos.
export function CopyForAgent({ text, label = "Copiar para tu agente", shortcut = "⌘⇧C", className }: { text: string; label?: string; shortcut?: string | null; className?: string }) {
  const [copied, setCopied] = useState(false)

  useEffect(() => {
    if (!copied) return
    const timer = setTimeout(() => setCopied(false), 2400)
    return () => clearTimeout(timer)
  }, [copied])

  const copy = async () => {
    try {
      await navigator.clipboard.writeText(text)
    } catch {
      /* sin portapapeles (http): se confirma igual para no bloquear */
    }
    setCopied(true)
  }

  return (
    <button
      type="button"
      onClick={copy}
      aria-live="polite"
      className={cx(
        "inline-flex h-8 items-center gap-2 rounded-md px-2 text-control whitespace-nowrap transition-colors",
        copied ? "bg-muted text-foreground" : "text-muted-foreground hover:text-foreground",
        className,
      )}
    >
      <Icon name={copied ? "check" : "copy"} size={14} />
      {copied ? "Copiado · pégalo en Claude, Codex o el que uses" : label}
      {!copied && shortcut && <Kbd className="border-0 px-0">{shortcut}</Kbd>}
    </button>
  )
}
