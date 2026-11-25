import { cx } from "./cx"
import { Icon, type IconName } from "./icons"

// Tipo de tarea del taller (08): icono descriptivo + nombre. Grande en lo primero, pequeño en la lista.
export const taskTypes = {
  review: { label: "Revisar y dar el OK", icon: "check" },
  criteria: { label: "Escribir criterios", icon: "pencil" },
  answer: { label: "Responder", icon: "question" },
  design: { label: "Diseñar", icon: "design" },
  decide: { label: "Decidir", icon: "spark" },
} as const satisfies Record<string, { label: string; icon: IconName }>

export type TaskType = keyof typeof taskTypes

export function TaskTypeTile({ type }: { type: TaskType }) {
  return (
    <span title={taskTypes[type].label} className="inline-flex size-11 items-center justify-center rounded-lg border border-border bg-muted text-foreground">
      <Icon name={taskTypes[type].icon} size={17} />
      <span className="sr-only">{taskTypes[type].label}</span>
    </span>
  )
}

export function TaskTypeLabel({ type, className }: { type: TaskType; className?: string }) {
  return (
    <span className={cx("inline-flex items-center gap-1.5 font-mono text-label tracking-label text-muted-foreground uppercase", className)}>
      <Icon name={taskTypes[type].icon} size={12} />
      {taskTypes[type].label}
    </span>
  )
}
