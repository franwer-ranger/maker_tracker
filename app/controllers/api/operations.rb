# Las operaciones de la API, para GET /api. Es la fuente de verdad del CLI y
# del futuro MCP: cada endpoint nuevo se añade aquí.
module Api::Operations
  VERSION = 1

  ALL = [
    { method: "GET", path: "/api", params: {}, command: nil,
      description: "Versión de la API y lista de operaciones. No necesita token" },
    { method: "GET", path: "/api/projects", params: {}, command: "mt projects",
      description: "Proyectos: clave, nombre, hito actual y cuántas historias hay en curso" },

    # Leer (#016). Lo que lee un agente va también en data.markdown.
    { method: "GET", path: "/api/projects/:key/context", params: {}, command: "mt context",
      description: "Brief, últimas decisiones vigentes, hito actual y lo que está en curso" },
    { method: "GET", path: "/api/projects/:key/next", params: {}, command: "mt next",
      description: "Primera historia Lista y no bloqueada de los hitos abiertos, entera y con el motivo. NOTHING_READY si no hay" },
    { method: "GET", path: "/api/projects/:key/roadmap", params: { closed: "true para incluir los hitos cerrados" }, command: "mt roadmap [--closed]",
      description: "Hitos en orden con su objetivo y sus historias en orden; al final, la bandeja de ideas" },
    { method: "GET", path: "/api/projects/:key/stories", command: "mt list [--state …] [--milestone …] [--label …] [--mine]",
      params: { state: "idea | defining | ready | in_progress | done", milestone: "M2, su título o inbox", label: "una label", claimed_by: "nombre del actor o me" },
      description: "Lista historias con filtros" },
    { method: "GET", path: "/api/projects/:key/stories/:number", params: {}, command: "mt show PG-49",
      description: "Una historia en markdown con frontmatter (formato de docs/backlog/), con sus comentarios y últimos eventos" },
    { method: "GET", path: "/api/projects/:key/decisions", params: {}, command: "mt decisions",
      description: "Todas las decisiones, de la más reciente a la más antigua, marcando las sustituidas" },

    # Trabajar (#017). Todo queda a nombre del actor del token, con su evento.
    { method: "POST", path: "/api/projects/:key/stories/:number/start", params: {}, command: "mt start PG-49",
      description: "Reclama la historia y la pasa a En curso. CLAIMED_BY_OTHER si es de otro; warnings si no está Lista o está bloqueada" },
    { method: "POST", path: "/api/projects/:key/stories/:number/done", params: { commits: "lista de shas (opcional)", pr: "url de la PR (opcional)" },
      command: "mt done PG-49 [--commit sha]… [--pr url]", description: "Pasa la historia a Hecha con sus commits y su PR en el evento" },
    { method: "POST", path: "/api/projects/:key/stories/:number/release", params: { reason: "por qué la sueltas (obligatorio para agentes)" },
      command: "mt release PG-49 --reason \"…\"", description: "La devuelve a Lista y la libera" },
    { method: "POST", path: "/api/projects/:key/stories/:number/comments", params: { body: "markdown" },
      command: "mt comment PG-49 \"…\"", description: "Comenta en la historia" },
    { method: "POST", path: "/api/projects/:key/decisions", params: { title: "la decisión", body: "el porqué (markdown)", story: "PG-49 (opcional)", supersedes: "D-9 (opcional)" },
      command: "mt decide \"…\" --why \"…\" [--story PG-49] [--supersedes D-9]", description: "Registra una decisión. Devuelve su referencia (D-15)" }
  ].freeze
end
