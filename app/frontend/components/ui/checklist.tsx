import { Checkbox, CheckboxIndicator } from "@ui-sdk/react/checkbox"
import { Eyebrow } from "./eyebrow"
import { Icon } from "./icons"

// Checklist y lista en línea (10): criterios con casilla (UI SDK); lo secundario (fuera de alcance) en una línea.
export function Checklist({ title = "Criterios de aceptación", items, outOfScope, more }: { title?: string; items: { text: string; done?: boolean }[]; outOfScope?: string[]; more?: { label: string; href: string } }) {
  return (
    <section className="flex flex-col">
      <h2 className="pb-4 text-xl font-medium text-foreground">{title}</h2>
      {items.map((item) => (
        <label key={item.text} className="flex cursor-pointer items-center gap-3 border-t border-border py-3.5 text-sm text-foreground">
          <Checkbox defaultChecked={item.done} className="flex size-4 shrink-0 items-center justify-center rounded-sm border border-muted-foreground bg-card data-checked:border-foreground data-checked:bg-foreground">
            <CheckboxIndicator className="text-background"><Icon name="check" size={11} strokeWidth={2.4} /></CheckboxIndicator>
          </Checkbox>
          {item.text}
        </label>
      ))}
      {outOfScope && outOfScope.length > 0 && (
        <p className="flex flex-wrap items-baseline gap-3 border-t border-border pt-4 text-control text-muted-foreground">
          <Eyebrow>Fuera de alcance</Eyebrow>
          {outOfScope.join(" · ")}
        </p>
      )}
      {more && <a href={more.href} className="mt-3 text-control text-foreground underline underline-offset-2">{more.label}</a>}
    </section>
  )
}
