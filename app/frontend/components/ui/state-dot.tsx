import { cx } from "./cx"

const colors: Record<string, string> = {
  idea: "border border-state-idea",
  defining: "bg-state-defining",
  ready: "bg-state-ready",
  in_progress: "bg-signal agent-pulse",
  done: "bg-state-done",
}

// Estado como punto (DESIGN.md: nunca como fondo grande).
export function StateDot({ state, className }: { state?: string; className?: string }) {
  return <span aria-hidden="true" className={cx("inline-block size-1.5 shrink-0 rounded-full", colors[state ?? ""] ?? "bg-state-idea", className)} />
}
