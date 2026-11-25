type Rule = { title: string; text?: string; decision?: string }

// Reglas y preguntas (10): lista con separadores finos; la decisión que la respalda, a la derecha en mono.
export function Rules({ items }: { items: Rule[] }) {
  return (
    <ul className="flex flex-col">
      {items.map((rule) => (
        <li key={rule.title} className="flex items-start justify-between gap-4 border-t border-border py-4">
          <div className="flex flex-col gap-1">
            <span className="text-sm font-medium text-foreground">{rule.title}</span>
            {rule.text && <span className="text-sm text-body">{rule.text}</span>}
          </div>
          {rule.decision && <span className="shrink-0 font-mono text-label text-muted-foreground">{rule.decision}</span>}
        </li>
      ))}
    </ul>
  )
}
