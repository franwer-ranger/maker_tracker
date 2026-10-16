# Las operaciones de la API, para GET /api. Es la fuente de verdad del CLI y
# del futuro MCP: cada endpoint nuevo se añade aquí.
module Api::Operations
  VERSION = 1

  ALL = [
    { method: "GET", path: "/api", params: {}, command: nil,
      description: "Versión de la API y lista de operaciones. No necesita token" },
    { method: "GET", path: "/api/projects", params: {}, command: "mt projects",
      description: "Proyectos: clave, nombre, hito actual y cuántas historias hay en curso" }
  ].freeze
end
