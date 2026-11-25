import { Link } from "@inertiajs/react"
import type { ReactNode } from "react"

// Barra superior (10): migas a la izquierda; a la derecha solo acciones ligeras (icono + texto gris + atajo).
export function TopBar({ crumbs, actions }: { crumbs: { label: string; href?: string }[]; actions?: ReactNode }) {
  return (
    <div className="flex h-14 shrink-0 items-center justify-between gap-4 border-b border-border px-7">
      <nav aria-label="Migas" className="flex min-w-0 items-center gap-2 text-control">
        {crumbs.map((crumb, index) => {
          const last = index === crumbs.length - 1
          return (
            <span key={crumb.label} className="flex min-w-0 items-center gap-2">
              {index > 0 && <span aria-hidden="true" className="text-muted-foreground">/</span>}
              {crumb.href && !last ? (
                <Link href={crumb.href} className="truncate text-muted-foreground hover:text-foreground">{crumb.label}</Link>
              ) : (
                <span aria-current={last ? "page" : undefined} className={last ? "truncate text-foreground" : "truncate text-muted-foreground"}>{crumb.label}</span>
              )}
            </span>
          )
        })}
      </nav>
      {actions && <div className="hidden items-center gap-2 md:flex">{actions}</div>}
    </div>
  )
}
