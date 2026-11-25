import { Fragment } from "react"

// El markdown en línea de la documentación (MT-103): `código` en mono, **negrita**, *énfasis* y [enlaces](url).
// Lo demás sale como texto: los bloques ya los parte Page::Reading en el servidor.
const token = /(`[^`]+`|\*\*[^*]+\*\*|\*[^*\s][^*]*\*|_[^_\s][^_]*_|\[[^\]]+\]\([^)\s]+\))/

export function InlineMarkdown({ text }: { text: string }) {
  return text.split(token).map((part, index) => {
    if (!part) return null
    if (part.startsWith("`") && part.endsWith("`") && part.length > 1) return <code key={index} className="font-mono text-[0.92em]">{part.slice(1, -1)}</code>
    if (part.startsWith("**") && part.endsWith("**") && part.length > 4) return <strong key={index} className="font-medium text-foreground">{part.slice(2, -2)}</strong>
    if (/^(\*[^*].*\*|_[^_].*_)$/.test(part)) return <em key={index}>{part.slice(1, -1)}</em>
    const link = part.match(/^\[([^\]]+)\]\(([^)\s]+)\)$/)
    // Solo enlaces web, relativos o anclas: nunca `javascript:`.
    if (link && /^(https?:\/\/|\/|#|mailto:)/i.test(link[2])) return <a key={index} href={link[2]} className="underline decoration-border underline-offset-2 hover:decoration-foreground">{link[1]}</a>
    return <Fragment key={index}>{part}</Fragment>
  })
}
