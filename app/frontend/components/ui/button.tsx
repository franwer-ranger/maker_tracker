import { Button as Base } from "@ui-sdk/react/button"
import type { ComponentProps } from "react"
import { cx } from "./cx"

// Botón (MT-87 · 08 Componentes base): uno solo en tinta por pantalla; el resto, acción ligera.
const variants = {
  primary: "bg-primary text-primary-foreground hover:opacity-90",
  quiet: "text-muted-foreground hover:bg-muted hover:text-foreground",
  outline: "border border-border bg-card text-foreground hover:bg-muted",
}

type Props = ComponentProps<typeof Base> & { variant?: keyof typeof variants }

export function Button({ variant = "primary", className, ...props }: Props) {
  return (
    <Base
      {...props}
      className={cx(
        "inline-flex h-8 items-center gap-2 rounded-md px-3 text-control font-medium transition-colors data-disabled:opacity-50 data-pending:opacity-70",
        variants[variant],
        typeof className === "string" && className,
      )}
    />
  )
}
