// Claro u oscuro según el sistema (MT-87: los dos en la v1). Sin selector en esta prueba.
const query = window.matchMedia("(prefers-color-scheme: dark)")

export function applyTheme() {
  const set = () => document.documentElement.classList.toggle("dark", query.matches)
  set()
  query.addEventListener("change", set)
}
