# Basecoat (copia)

[Basecoat](https://basecoatui.com/) da los componentes de shadcn/ui en HTML y CSS, sin React.
Aquí está **copiado, no instalado** (filosofía shadcn: copiar, no depender): no hay npm ni en
desarrollo ni en producción y lo compila `tailwindcss-rails` con el resto del CSS.

- **Versión:** `basecoat-css` 1.3.0 (npm, `dist/`), copiada el 2026-11-23 (MT-86).
- **Licencia:** MIT, © 2025 Ronan Berder. Texto en `vendor/licenses/basecoat-MIT.txt`.
- **Qué hay:** la base (`base/`) y los componentes (`components/`), con sus ficheros de entrada
  `basecoat-base.css` y `basecoat-components.css`, tal cual. **Sin paquete de estilos** (`styles/*`,
  vega, nova…) ni el JS (`dist/js`): el tema es el nuestro.
- **Dónde se usa:** `app/assets/tailwind/application.css` lo importa antes del tema de Maker Tracker,
  que da valor a las variables de shadcn (`--background`, `--primary`…) con los tokens de
  `docs/DESIGN.md`.

No edites estos ficheros: para actualizar, sustituye la carpeta por la de la versión nueva y cambia
la versión de arriba. Lo que haya que adaptar va en `app/assets/tailwind/application.css`.
