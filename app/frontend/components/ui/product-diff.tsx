import { Icon, type IconName } from "./icons"

type Block = { capability: string; icon?: IconName; adds: string[]; keeps?: string[] }

// Diff del producto (10): una capacidad por bloque. + lo que añade (verde), = lo que no cambia (gris).
export function ProductDiff({ blocks, note = "Al cerrarla, estas páginas quedan al día" }: { blocks: Block[]; note?: string }) {
  return (
    <section className="flex flex-col gap-4">
      <div className="flex items-baseline justify-between gap-4 border-b border-border pb-4">
        <h2 className="text-xl font-medium text-foreground">Qué cambia del producto</h2>
        <span className="text-control text-muted-foreground">{note}</span>
      </div>
      {blocks.map((block) => (
        <div key={block.capability} className="flex gap-4">
          <span className="inline-flex size-9 shrink-0 items-center justify-center rounded-md bg-muted text-foreground">
            <Icon name={block.icon ?? "file"} size={14} />
          </span>
          <div className="flex min-w-0 flex-col gap-2">
            <span className="text-base font-medium text-foreground">{block.capability}</span>
            <ul className="flex flex-col gap-1.5 text-sm">
              {block.adds.map((line) => (
                <li key={line} className="flex gap-3 text-foreground"><span aria-label="añade" className="w-3 font-mono text-success">+</span>{line}</li>
              ))}
              {block.keeps?.map((line) => (
                <li key={line} className="flex gap-3 text-muted-foreground"><span aria-label="no cambia" className="w-3 font-mono">=</span>{line}</li>
              ))}
            </ul>
          </div>
        </div>
      ))}
    </section>
  )
}
