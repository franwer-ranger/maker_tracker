import { useSyncExternalStore } from "react"

// Tema (MT-101): por defecto sigue al sistema; se puede fijar a mano en claro u oscuro (se guarda en este navegador).
export type ThemeChoice = "system" | "light" | "dark"

const KEY = "mt-theme"
const query = window.matchMedia("(prefers-color-scheme: dark)")
const listeners = new Set<() => void>()

function read(): ThemeChoice {
  try {
    const value = localStorage.getItem(KEY)
    return value === "light" || value === "dark" ? value : "system"
  } catch {
    return "system"
  }
}

let choice: ThemeChoice = read()

function paint() {
  const dark = choice === "dark" || (choice === "system" && query.matches)
  document.documentElement.classList.toggle("dark", dark)
}

export function applyTheme() {
  paint()
  query.addEventListener("change", () => {
    paint()
    listeners.forEach((listener) => listener())
  })
}

export function setTheme(next: ThemeChoice) {
  choice = next
  try {
    if (next === "system") localStorage.removeItem(KEY)
    else localStorage.setItem(KEY, next)
  } catch {
    /* sin almacenamiento: solo esta visita */
  }
  paint()
  listeners.forEach((listener) => listener())
}

export const isDark = () => document.documentElement.classList.contains("dark")

// Elección y tema efectivo, para el selector y el ⌘K («Ahora: claro»).
export function useTheme() {
  return useSyncExternalStore(
    (listener) => {
      listeners.add(listener)
      return () => listeners.delete(listener)
    },
    () => `${choice}:${isDark() ? "dark" : "light"}`,
  )
}
