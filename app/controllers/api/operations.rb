# Las operaciones de la API, para GET /api. Es la fuente de verdad del CLI y
# del futuro MCP: cada endpoint nuevo se añade aquí.
module Api::Operations
  VERSION = 1

  ALL = [
    { method: "GET", path: "/api", params: {}, command: nil,
      description: "API version and list of operations. Needs no token" },
    { method: "GET", path: "/api/projects", params: {}, command: "mt projects",
      description: "Projects: key, name, current milestone and how many stories are in progress" },

    # Leer (#016). Lo que lee un agente va también en data.markdown (docs/CLI.md).
    { method: "GET", path: "/api/projects/:key/context", params: {}, command: "mt context",
      description: "Brief, latest decisions in force, current milestone and what is in progress" },
    { method: "GET", path: "/api/projects/:key/next", params: {}, command: "mt next",
      description: "First ready, unblocked story of the open milestones, whole and with why. NOTHING_READY if there is none" },
    { method: "GET", path: "/api/projects/:key/roadmap", params: { closed: "true to include closed milestones" }, command: "mt roadmap [--closed]",
      description: "Open milestones in order with their goal and stories in order, then the inbox" },
    { method: "GET", path: "/api/projects/:key/stories", command: "mt list [--state …] [--milestone …] [--label …] [--mine]",
      params: { state: "idea | defining | ready | in_progress | done", milestone: "M2, its title or inbox", label: "a label", claimed_by: "actor name or me" },
      description: "Lists stories with filters" },
    { method: "GET", path: "/api/projects/:key/stories/:number", params: {}, command: "mt show PG-49",
      description: "A story as markdown with frontmatter (the docs/backlog/ format), with related stories, comments and latest events" },
    { method: "GET", path: "/api/projects/:key/decisions", params: {}, command: "mt decisions",
      description: "All decisions, newest first, marking the superseded ones" },

    # Trabajar (#017). Todo queda a nombre del actor del token, con su evento.
    { method: "POST", path: "/api/projects/:key/stories/:number/start", params: {}, command: "mt start PG-49",
      description: "Claims the story and moves it to in_progress. CLAIMED_BY_OTHER if someone else has it; warnings if it was not ready, is blocked or has no criteria" },
    { method: "POST", path: "/api/projects/:key/stories/:number/done", params: { commits: "list of shas (optional)", pr: "PR url (optional)" },
      command: "mt done PG-49 [--commit sha]… [--pr url]", description: "Moves the story to done with its commits and PR in the event" },
    { method: "POST", path: "/api/projects/:key/stories/:number/release", params: { reason: "why you release it (required for agents)" },
      command: "mt release PG-49 --reason \"…\"", description: "Moves it back to ready and unclaims it" },
    { method: "POST", path: "/api/projects/:key/stories/:number/comments", params: { body: "markdown" },
      command: "mt comment PG-49 \"…\"", description: "Comments on the story" },
    { method: "POST", path: "/api/projects/:key/decisions", params: { title: "the decision", body: "the why (markdown)", story: "PG-49 (optional)", supersedes: "D-9 (optional)" },
      command: "mt decide \"…\" --why \"…\" [--story PG-49] [--supersedes D-9]", description: "Records a decision. Returns its reference (D-15)" },

    # Definir producto (#018). Nada se borra; cada cambio deja su evento.
    { method: "POST", path: "/api/projects/:key/stories", command: "mt create \"Title\" [--milestone M2] [--state …] [--number 14] [--file f.md]",
      params: { markdown: "the story in the mt show format (or the separate fields)", title: "", milestone: "M2, its title or inbox", state: "idea | defining | ready",
                body: "markdown; without it, the template", mockup: "url", labels: "list", blocked_by: "list of numbers",
                number: "keeps this number if it is free (to migrate a backlog); without it, the next one" },
      description: "Creates a story. Without state it is an idea, and without milestone it goes to the inbox" },
    { method: "PATCH", path: "/api/projects/:key/stories/:number", command: "mt edit PG-49 --file f.md",
      params: { markdown: "the story in the mt show format", title: "", body: "", mockup: "", labels: "", blocked_by: "" },
      description: "Edits title, body and properties; number is ignored. Changing state or milestone is an error: use move or reorder" },
    { method: "POST", path: "/api/projects/:key/stories/:number/move", params: { state: "idea | defining | ready | in_progress | done" },
      command: "mt move PG-49 ready", description: "Changes the state. Moving to ready without meeting the rule gives warnings" },
    { method: "POST", path: "/api/projects/:key/stories/:number/reorder", command: "mt reorder PG-49 --position 1 [--milestone M3] --reason \"…\"",
      params: { position: "from 1; without it, at the end", milestone: "M3, its title or inbox", reason: "required for agents" },
      description: "Reorders the story in its milestone or moves it to another" },
    { method: "POST", path: "/api/projects/:key/milestones", params: { title: "", goal: "markdown" },
      command: "mt milestone create \"Title\" [--goal \"…\"]", description: "Creates a milestone at the end of the roadmap" },
    { method: "PATCH", path: "/api/projects/:key/milestones/:code", params: { title: "", goal: "markdown" },
      command: "mt milestone edit M2 [--title …] [--goal …]", description: "Edits a milestone's title or goal" },
    { method: "POST", path: "/api/projects/:key/milestones/:code/reorder", params: { position: "from 1", reason: "required for agents" },
      command: "mt milestone reorder M3 --position 2 --reason \"…\"", description: "Changes a milestone's position (and with it, its code)" },
    { method: "POST", path: "/api/projects/:key/milestones/:code/close", params: {}, command: "mt milestone close M2", description: "Closes a milestone" },
    { method: "POST", path: "/api/projects/:key/milestones/:code/reopen", params: {}, command: "mt milestone reopen M2", description: "Reopens a milestone" },
    { method: "GET", path: "/api/projects/:key/brief", params: {}, command: "mt brief", description: "The brief as markdown" },
    { method: "PUT", path: "/api/projects/:key/brief", params: { markdown: "the whole brief" }, command: "mt brief --file f.md", description: "Replaces the brief" }
  ].freeze
end
