import { cx } from "./cx"
import { states, type StoryState } from "./state"

// Estado como punto suelto (listas densas, ⌘K). El de En curso late: es vida.
export function StateDot({ state, className }: { state?: string; className?: string }) {
  const known = state && state in states ? states[state as StoryState] : null
  return (
    <span
      aria-hidden="true"
      className={cx("inline-block size-1.5 shrink-0 rounded-full", known?.dot ?? "bg-state-idea", state === "in_progress" && "agent-pulse", className)}
    />
  )
}
