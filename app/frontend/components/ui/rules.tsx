import type { ReactNode } from "react"

type Rule = { title: ReactNode; text?: ReactNode; decision?: string }

// Reglas y preguntas (10, «v1 · 3 · Capacidad»): lista con separadores finos; la decisión que la respalda, a la derecha en mono.
export function Rules({ items }: { items: Rule[] }) {
  return (
    <ul className="flex flex-col">
      {items.map((rule, index) => (
        <li key={index} className="grid grid-cols-[1fr_auto] gap-4 border-t border-border py-3.5">
          <div className="flex min-w-0 flex-col gap-[3px]">
            <span className="text-[15px] leading-[18px] font-medium text-foreground">{rule.title}</span>
            {rule.text && <span className="text-sm leading-[21px] text-body">{rule.text}</span>}
          </div>
          {rule.decision && <span className="font-mono text-label leading-[22px] text-muted-foreground">{rule.decision}</span>}
        </li>
      ))}
    </ul>
  )
}
