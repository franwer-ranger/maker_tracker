import { Command, CommandEmpty, CommandInput, CommandItem, CommandItemText, CommandList } from "@ui-sdk/react/command"
import { Popover, PopoverContent, PopoverTitle, PopoverTrigger } from "@ui-sdk/react/popover"
import { type ReactNode, useState } from "react"
import { cx } from "./cx"
import { Icon } from "./icons"

export type ComboOption = { value: string; label: string }

// Combo (08): Popover + Command de UI SDK, como el de producto, con buscador para muchas opciones.
// `trigger` cambia lo que se ve en el botón (el de filtros en móvil es solo un icono); el nombre accesible es el mismo.
export function Combo({ label, value, options, onChange, className, trigger }: { label: string; value: string; options: ComboOption[]; onChange: (value: string) => void; className?: string; trigger?: ReactNode }) {
  const [open, setOpen] = useState(false)
  const current = options.find((option) => option.value === value) ?? options[0]
  return (
    <Popover open={open} onOpenChange={setOpen}>
      <PopoverTrigger aria-label={`${label}: ${current.label}`} className={cx("flex items-center justify-between gap-2 rounded-lg border border-border bg-card py-2 pr-2.5 pl-3 text-sm leading-[18px] text-foreground hover:bg-muted", className)}>
        {trigger ?? (
          <>
            <span className="truncate">{current.label}</span>
            <Icon name="chevronDown" size={12} strokeWidth={2} className="text-muted-foreground" />
          </>
        )}
      </PopoverTrigger>
      <PopoverContent side="bottom" align="start" sideOffset={6} className="z-50 w-[280px] overflow-hidden rounded-xl border border-border bg-card text-foreground shadow-[0_12px_32px_rgba(15,15,17,0.14)]">
        <PopoverTitle className="sr-only">{label}</PopoverTitle>
        <Command onAction={(next) => { onChange(next); setOpen(false) }} className="flex flex-col">
          <div className="flex h-11 items-center gap-2.5 border-b border-border px-3 text-muted-foreground">
            <Icon name="search" size={14} />
            <CommandInput aria-label={`Buscar ${label.toLowerCase()}`} placeholder="Buscar…" className="h-full flex-1 bg-transparent text-sm text-foreground outline-none placeholder:text-muted-foreground focus-visible:shadow-none" />
          </div>
          <CommandEmpty className="px-3 py-4 text-control text-muted-foreground not-data-empty:hidden">{(state) => `Nada con «${state.query}».`}</CommandEmpty>
          <CommandList className="max-h-72 overflow-y-auto">
            {options.map((option) => (
              <CommandItem key={option.value} value={option.value} label={option.label} className="flex h-10 cursor-default items-center gap-2.5 px-3 text-sm data-highlighted:bg-muted">
                <CommandItemText className="min-w-0 flex-1 truncate [&_mark]:bg-transparent [&_mark]:font-semibold [&_mark]:text-foreground">{option.label}</CommandItemText>
                {option.value === value && <Icon name="check" size={13} className="text-muted-foreground" />}
              </CommandItem>
            ))}
          </CommandList>
        </Command>
      </PopoverContent>
    </Popover>
  )
}
