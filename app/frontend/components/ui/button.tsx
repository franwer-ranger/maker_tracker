import { Button as Base } from "@ui-sdk/react/button"
import type { ComponentProps, ReactNode } from "react"
import { cx } from "./cx"
import { Kbd } from "./kbd"

// Botones (08 · Componentes base): principal en tinta (uno por pantalla, con su atajo),
// secundario con borde y fantasma solo texto. El naranja nunca es un botón.
const variants = {
  primary: "bg-primary px-3.5 text-primary-foreground hover:opacity-90",
  secondary: "border border-border bg-card px-3 text-foreground hover:bg-muted",
  ghost: "px-2 text-foreground hover:bg-muted",
}

type Props = ComponentProps<typeof Base> & { variant?: keyof typeof variants; shortcut?: string }

export function Button({ variant = "primary", shortcut, className, children, ...props }: Props) {
  return (
    <Base
      {...props}
      className={cx(
        "inline-flex h-8 items-center gap-2.5 rounded-md text-sm whitespace-nowrap transition-colors data-disabled:opacity-50 data-pending:opacity-70",
        variants[variant],
        typeof className === "string" && className,
      )}
    >
      {children as ReactNode}
      {shortcut && <Kbd tone={variant === "primary" ? "ink" : "panel"}>{shortcut}</Kbd>}
    </Base>
  )
}
