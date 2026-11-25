import { Fragment } from "react"

// El markdown en línea de la documentación (MT-103): `código` en mono, **negrita**, *énfasis*, [enlaces](url) e
// ![imágenes](url) (MT-122: las adjuntas llegan resueltas; la que cita un adjunto que no existe, `attachment:x.png`,
// sale como un hueco con «Falta la imagen x.png», nunca rota). Lo demás sale como texto: los bloques ya los parte
// Page::Reading en el servidor.
const token = /(`[^`]+`|\*\*[^*]+\*\*|\*[^*\s][^*]*\*|_[^_\s][^_]*_|!\[[^\]]*\]\([^)\s]+\)|\[[^\]]+\]\([^)\s]+\))/
// Solo enlaces web, relativos o anclas: nunca `javascript:`.
const safe = /^(https?:\/\/|\/|#|mailto:)/i
const video = /\.(mp4|webm|mov)$/i

export function InlineMarkdown({ text }: { text: string }) {
  return text.split(token).map((part, index) => {
    if (!part) return null
    if (part.startsWith("`") && part.endsWith("`") && part.length > 1) return <code key={index} className="font-mono text-[0.92em]">{part.slice(1, -1)}</code>
    if (part.startsWith("**") && part.endsWith("**") && part.length > 4) return <strong key={index} className="font-medium text-foreground">{part.slice(2, -2)}</strong>
    if (/^(\*[^*].*\*|_[^_].*_)$/.test(part)) return <em key={index}>{part.slice(1, -1)}</em>
    const image = part.match(/^!\[([^\]]*)\]\(([^)\s]+)\)$/)
    if (image) return <Image key={index} alt={image[1]} src={image[2]} />
    const link = part.match(/^\[([^\]]+)\]\(([^)\s]+)\)$/)
    if (link && safe.test(link[2])) return <a key={index} href={link[2]} className="underline decoration-border underline-offset-2 hover:decoration-foreground">{link[1]}</a>
    return <Fragment key={index}>{part}</Fragment>
  })
}

function Image({ alt, src }: { alt: string; src: string }) {
  if (src.startsWith("attachment:")) return <MissingImage name={decodeName(src.slice("attachment:".length))} />
  if (!safe.test(src)) return <>{alt}</>
  if (video.test(src.split(/[?#]/)[0])) {
    return <video src={src} controls preload="metadata" aria-label={alt} className="my-1 block max-w-full rounded-md border border-border" />
  }
  return (
    <a href={src} target="_blank" rel="noreferrer" className="my-1 block w-fit max-w-full">
      <img src={src} alt={alt} loading="lazy" className="block max-h-[480px] max-w-full rounded-md border border-border" />
    </a>
  )
}

// El hueco de una imagen que cita un adjunto que no hay.
function MissingImage({ name }: { name: string }) {
  return (
    <span role="img" aria-label={`Falta la imagen ${name}`} className="my-1 block w-fit max-w-full rounded-md border border-dashed border-border px-3 py-2 text-control text-muted-foreground">
      Falta la imagen{" "}<span className="font-mono">{name}</span>
    </span>
  )
}

function decodeName(name: string) {
  try {
    return decodeURIComponent(name)
  } catch {
    return name
  }
}
