import { cx } from "./cx"

// Estado de una historia (08): punto + nombre en una píldora con borde. Nunca color de fondo.
export const states = {
  idea: { label: "Idea", dot: "bg-state-idea" },
  defining: { label: "Definiendo", dot: "bg-state-defining" },
  ready: { label: "Lista", dot: "bg-state-ready" },
  in_progress: { label: "En curso", dot: "bg-state-in-progress" },
  done: { label: "Hecha", dot: "bg-state-done" },
} as const

export type StoryState = keyof typeof states

export function StateBadge({ state, className }: { state: StoryState; className?: string }) {
  const { label, dot } = states[state]
  return (
    <span className={cx("inline-flex h-6 items-center gap-2 rounded-full border border-border bg-card px-2.5 text-control text-foreground", className)}>
      <span aria-hidden="true" className={cx("size-1.5 rounded-full", dot)} />
      {label}
    </span>
  )
}
