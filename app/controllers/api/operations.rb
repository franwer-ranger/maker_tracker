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
      description: "Todas las decisiones, de la más reciente a la más antigua, marcando las sustituidas" }
  ].freeze
end
