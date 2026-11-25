import { cx } from "./cx"
import { PresenceWho } from "./presence"

// Vida · el agente trabajando (08, 09): el único naranja que se mueve. En la barra lateral, con robot;
// en el panel, solo si toca lo que estás viendo.
// `human`: una persona que trabaja por la API (MT-100), con su inicial en vez del robot.
export function AgentWorking({ agent, human = false, target, variant = "sidebar", className }: { agent: string; human?: boolean; target?: string | null; variant?: "sidebar" | "chip" | "inline"; className?: string }) {
  if (variant === "inline") {
    return (
      <span className={cx("inline-flex items-center gap-2 text-control text-muted-foreground", className)}>
        <span aria-hidden="true" className="agent-pulse size-1.5 rounded-full bg-signal" />
        <span className="font-mono text-label text-foreground">{agent}</span>
        {target ?? "está trabajando"}
      </span>
    )
  }
  return (
    <span
      className={cx(
        "inline-flex items-center gap-2 font-mono text-label",
        variant === "chip" && "rounded-md bg-sidebar px-3.5 py-2.5",
        className,
      )}
    >
      {variant === "chip" ? (
        <span aria-hidden="true" className="agent-pulse size-1.5 rounded-full bg-signal" />
      ) : (
        <PresenceWho agent={!human} name={agent} />
      )}
      <span className="text-sidebar-foreground">{agent}</span>
      <span className="text-sidebar-muted">trabaja{target ? ` en ${target}` : ""}</span>
    </span>
  )
}
