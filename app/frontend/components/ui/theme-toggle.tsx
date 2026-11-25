import { type ThemeChoice, setTheme, useTheme } from "@/lib/theme"
import { Icon } from "./icons"

const next: Record<ThemeChoice, ThemeChoice> = { system: "light", light: "dark", dark: "system" }
const names: Record<ThemeChoice, string> = { system: "Sistema", light: "Claro", dark: "Oscuro" }

// Selector de tema (MT-101): sistema → claro → oscuro. Por defecto sigue al sistema.
export function ThemeToggle({ className }: { className?: string }) {
  const choice = useTheme().split(":")[0] as ThemeChoice
  return (
    <button
      type="button"
      onClick={() => setTheme(next[choice])}
      title={`Tema: ${names[choice]}`}
      aria-label={`Tema: ${names[choice]}. Cambiar a ${names[next[choice]].toLowerCase()}`}
      className={className ?? "flex items-center gap-1 rounded-sm px-1 font-mono text-[10px] text-sidebar-muted hover:text-sidebar-foreground"}
    >
      <Icon name="contrast" size={13} />
      {names[choice]}
    </button>
  )
}
