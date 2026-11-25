import { router } from "@inertiajs/react"
import { Command, CommandEmpty, CommandInput, CommandItem, CommandItemText, CommandList } from "@ui-sdk/react/command"
import { Popover, PopoverContent, PopoverTitle, PopoverTrigger } from "@ui-sdk/react/popover"
import { useState } from "react"
import { cx } from "./cx"
import { Icon } from "./icons"
import { Kbd } from "./kbd"

// `count` (el taller, MT-97): cuántas cosas tiene ese producto; `logo`: la imagen del producto (MT-96), si la tiene.
type Product = { key: string; name: string; url: string; count?: number; logo?: string | null }

// Combo de producto (08): un producto por pantalla, dropdown con buscador que escala a muchos.
// Logo (la clave del producto) y nombre. Comportamiento: Popover + Command de UI SDK.
// `shortcut` (P) solo en una instancia por pantalla: el registro de atajos no mira si está visible.
export function ProductCombo({ products, current, tone = "sidebar", shortcut }: { products: Product[]; current: string; tone?: "sidebar" | "panel"; shortcut?: string }) {
  const [open, setOpen] = useState(false)
  const active = products.find((product) => product.key === current)

  const choose = (key: string) => {
    const product = products.find((item) => item.key === key)
    setOpen(false)
    if (product && product.key !== current) router.visit(product.url)
  }

  return (
    <Popover open={open} onOpenChange={setOpen}>
      <PopoverTrigger
        shortcut={shortcut}
        className={cx(
          "flex w-full items-center justify-between gap-2 rounded-lg border px-2.5 py-2 text-sm",
          tone === "sidebar" ? "border-sidebar-control text-sidebar-active hover:bg-sidebar-accent" : "border-border bg-card text-foreground hover:bg-muted",
        )}
      >
        <span className="flex min-w-0 items-center gap-2.5">
          <ProductMark code={active?.key ?? current} logo={active?.logo} />
          <span className="truncate">{active?.name ?? current}</span>
          {active?.count !== undefined && <span className="font-mono text-label text-muted-foreground">{active.count}</span>}
        </span>
        <Icon name="chevronDown" size={12} strokeWidth={2} className={tone === "sidebar" ? "text-sidebar-muted" : "text-muted-foreground"} />
      </PopoverTrigger>
      <PopoverContent side="bottom" align="start" sideOffset={6} className="z-50 w-[280px] overflow-hidden rounded-xl border border-border bg-card text-foreground shadow-[0_12px_32px_rgba(15,15,17,0.14)]">
        <PopoverTitle className="sr-only">Cambiar de producto</PopoverTitle>
        <Command onAction={choose} className="flex flex-col">
          <div className="flex h-11 items-center gap-2.5 border-b border-border px-3 text-muted-foreground">
            <Icon name="search" size={14} />
            <CommandInput aria-label="Buscar producto" placeholder="Buscar producto…" className="h-full flex-1 bg-transparent text-sm text-foreground outline-none placeholder:text-muted-foreground focus-visible:shadow-none" />
          </div>
          <CommandEmpty className="px-3 py-4 text-control text-muted-foreground not-data-empty:hidden">{(state) => `Ningún producto con «${state.query}».`}</CommandEmpty>
          <CommandList className="max-h-72 overflow-y-auto">
            {products.map((product) => (
              <CommandItem key={product.key} value={product.key} label={`${product.name} ${product.key}`} className="flex h-10 cursor-default items-center gap-2.5 px-3 text-sm data-highlighted:bg-muted">
                <ProductMark code={product.key} logo={product.logo} />
                <CommandItemText className="min-w-0 flex-1 truncate [&_mark]:bg-transparent [&_mark]:font-semibold [&_mark]:text-foreground">{product.name}</CommandItemText>
                {product.count !== undefined && <span className="font-mono text-label text-muted-foreground">{product.count}</span>}
                {product.key === current && <Icon name="check" size={13} className="text-muted-foreground" />}
              </CommandItem>
            ))}
          </CommandList>
          <div className="flex h-9 items-center justify-between border-t border-border px-3 text-control text-muted-foreground">
            <span>↑↓ para moverte · ↵ elegir</span>
            {shortcut && <Kbd>{shortcut.toUpperCase()}</Kbd>}
          </div>
        </Command>
      </PopoverContent>
    </Popover>
  )
}

// Marca del producto: su logo (MT-96) o, sin él, casilla de 18px con la inicial de su clave (sin logos inventados).
export function ProductMark({ code, logo, size = 18 }: { code: string; logo?: string | null; size?: number }) {
  if (logo) return <img src={logo} alt="" aria-hidden="true" style={{ width: size, height: size }} className="shrink-0 rounded-[5px] object-cover" />
  return (
    <span
      aria-hidden="true"
      style={{ width: size, height: size }}
      className="inline-flex shrink-0 items-center justify-center rounded-[5px] bg-sidebar-chip font-mono text-[10px] text-sidebar-active"
    >
      {code.slice(0, 2)}
    </span>
  )
}
