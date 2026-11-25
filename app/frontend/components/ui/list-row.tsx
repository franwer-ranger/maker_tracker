import type { ReactNode } from "react"
import { Eyebrow } from "./eyebrow"
import { TaskTypeLabel, type TaskType } from "./task-type"

// Fila de lista (08): número de orden en mono, lo que es y por qué, y a la derecha el tipo y una acción secundaria.
// Columnas de ancho fijo para que las filas se alineen.
export function ListRow({ index, title, reason, refs, type, action }: { index: string; title: ReactNode; reason?: ReactNode; refs?: string[]; type?: TaskType; action?: ReactNode }) {
  return (
    <div className="flex items-start gap-4 border-b border-border py-4 first:border-t">
      <span className="w-6 shrink-0 pt-0.5 font-mono text-control text-muted-foreground">{index}</span>
      <div className="flex min-w-0 flex-1 flex-col gap-1">
        <span className="text-base font-medium text-foreground">{title}</span>
        {(reason || refs) && (
          <span className="text-control text-muted-foreground">
            {reason}
            {refs && refs.length > 0 && <span className="ml-1 font-mono text-label">{refs.join(" · ")}</span>}
          </span>
        )}
      </div>
      {(type || action) && (
        <div className="flex w-44 shrink-0 flex-col items-end gap-2">
          {type && <TaskTypeLabel type={type} />}
          {action}
        </div>
      )}
    </div>
  )
}

export { Eyebrow }
