import { Radio, RadioGroup, RadioIndicator } from "@ui-sdk/react/radio"
import { useState } from "react"
import { Button } from "./button"
import { cx } from "./cx"
import { Eyebrow } from "./eyebrow"
import { FocusSignal } from "./focus-signal"
import { Icon } from "./icons"

type Option = { value: string; label: string; detail?: string; recommended?: boolean }

// Pregunta abierta (10): borde completo, nunca raya lateral. Naranja solo en el punto de bloqueo.
// «Responder» es el botón en tinta de la pantalla. Comportamiento del grupo de radios: UI SDK.
export function OpenQuestion({ question, context, options, blocks, onAnswer }: { question: string; context?: string; options: Option[]; blocks?: string; onAnswer?: (value: string) => void }) {
  const [value, setValue] = useState(options.find((option) => option.recommended)?.value ?? options[0]?.value)

  return (
    <section className="flex flex-col gap-4 rounded-xl border border-border bg-card p-6">
      <div className="flex items-center justify-between gap-4">
        <span className="inline-flex items-center gap-2 text-foreground">
          <Icon name="question" size={14} />
          <Eyebrow className="text-foreground">Pregunta abierta</Eyebrow>
        </span>
        {blocks && <FocusSignal muted>{blocks}</FocusSignal>}
      </div>
      <h3 className="text-lg font-medium text-foreground">{question}</h3>
      {context && <p className="text-sm text-muted-foreground">{context}</p>}
      <RadioGroup value={value} onValueChange={(next) => next && setValue(next)} aria-label={question} className="flex flex-col gap-2">
        {options.map((option) => (
          <Radio
            key={option.value}
            value={option.value}
            className={cx(
              "flex items-center gap-3 rounded-lg border px-4 py-3 text-left transition-colors",
              option.value === value ? "border-foreground" : "border-border hover:bg-muted",
            )}
          >
            <span className="flex size-4 shrink-0 items-center justify-center rounded-full border border-muted-foreground">
              <RadioIndicator className="size-2 rounded-full bg-foreground" />
            </span>
            <span className="flex min-w-0 flex-1 flex-col">
              <span className="text-sm text-foreground">{option.label}</span>
              {option.detail && <span className="font-mono text-label text-muted-foreground">{option.detail}</span>}
            </span>
            {option.recommended && <Eyebrow>Recomendada</Eyebrow>}
          </Radio>
        ))}
      </RadioGroup>
      <div className="flex items-center justify-between gap-4">
        <span className="text-control text-muted-foreground">o responde con una nota</span>
        <Button shortcut="↵" onClick={() => value && onAnswer?.(value)}>Responder</Button>
      </div>
    </section>
  )
}
