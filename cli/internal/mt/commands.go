package mt

import (
	"fmt"
	"net/url"
	"os"
	"path/filepath"
	"regexp"
	"strconv"
	"strings"
)

type command struct {
	name             string // "next", "milestone create"
	group            string
	usage            string
	summary          string
	description      string
	example          string
	flags            map[string]flagKind
	flagHelp         map[string]string
	minArgs, maxArgs int // maxArgs -1: sin límite
	run              func(*env) error
}

var commands []*command

func findCommand(argv []string) *command {
	for _, n := range []int{2, 1} {
		if len(argv) < n {
			continue
		}
		name := strings.Join(argv[:n], " ")
		for _, cmd := range commands {
			if cmd.name == name {
				return cmd
			}
		}
	}
	return nil
}

// project: --project, la clave de la referencia (PG-49) o el .mt más cercano.
func (e *env) project(reference string) (string, error) {
	if key := e.opts.get("project"); key != "" {
		return strings.ToUpper(key), nil
	}
	if m := referencePattern.FindStringSubmatch(reference); m != nil && m[1] != "" {
		return strings.ToUpper(m[1]), nil
	}
	dir, err := os.Getwd()
	if err != nil {
		return "", err
	}
	key, _, err := findProject(dir)
	if err != nil {
		return "", err
	}
	if key == "" {
		return "", usageErrorf("no sé de qué proyecto hablas. Ejecuta mt init PG en la raíz del repo, usa --project PG o cita la historia como PG-49")
	}
	return key, nil
}

var referencePattern = regexp.MustCompile(`^(?i:([a-z]{2,5})-)?(\d+)$`)

// storyPath: /api/projects/PG/stories/49 a partir de PG-49 o 49.
func (e *env) storyPath(reference string) (string, error) {
	m := referencePattern.FindStringSubmatch(strings.TrimPrefix(reference, "#"))
	if m == nil {
		return "", usageErrorf("%q no es una historia: usa PG-49 o 49", reference)
	}
	key, err := e.project(reference)
	if err != nil {
		return "", err
	}
	return projectPath(key) + "/stories/" + m[2], nil
}

func (e *env) projectPath() (string, error) {
	key, err := e.project("")
	if err != nil {
		return "", err
	}
	return projectPath(key), nil
}

func projectPath(key string) string { return "/api/projects/" + url.PathEscape(key) }

// get/post sobre el proyecto actual.
func (e *env) projectCall(method, suffix string, query map[string]string, body any) error {
	base, err := e.projectPath()
	if err != nil {
		return err
	}
	return e.call(method, base+suffix, query, body)
}

func (e *env) storyCall(method, reference, suffix string, body any) error {
	path, err := e.storyPath(reference)
	if err != nil {
		return err
	}
	return e.call(method, path+suffix, nil, body)
}

// optional añade al cuerpo las flags que se han pasado.
func optional(body map[string]any, e *env, names ...string) map[string]any {
	for _, name := range names {
		if e.opts.has(name) {
			body[name] = e.opts.get(name)
		}
	}
	return body
}

func flags(spec ...string) (map[string]flagKind, map[string]string) {
	kinds, help := map[string]flagKind{}, map[string]string{}
	for _, s := range spec {
		name, rest, _ := strings.Cut(s, " ")
		kind := stringFlag
		switch {
		case strings.HasSuffix(name, "!"):
			kind, name = boolFlag, strings.TrimSuffix(name, "!")
		case strings.HasSuffix(name, "*"):
			kind, name = multiFlag, strings.TrimSuffix(name, "*")
		}
		kinds[name], help[name] = kind, rest
	}
	return kinds, help
}

func def(cmd *command, spec ...string) {
	cmd.flags, cmd.flagHelp = flags(spec...)
	commands = append(commands, cmd)
}

func init() {
	const setupGroup, readGroup, workGroup, defineGroup = "Configurar", "Leer", "Trabajar una historia", "Definir producto"

	def(&command{name: "setup", group: setupGroup, usage: "mt setup <url> <token>", minArgs: 2, maxArgs: 2,
		summary:     "Guarda la instancia y el token en ~/.config/mt/config y comprueba que funcionan",
		description: "El token se crea en el servidor con bin/rails \"mt:token[tu-nombre]\". MT_URL y MT_TOKEN tienen prioridad sobre el fichero.",
		example:     "mt setup https://torre.tu-tailnet.ts.net mt_…", run: runSetup})
	def(&command{name: "init", group: setupGroup, usage: "mt init <CLAVE> [--claude]", minArgs: 1, maxArgs: 1,
		summary:     "Crea .mt con el proyecto en el directorio actual (la raíz del repo)",
		description: "mt busca .mt hacia arriba desde el directorio actual. Con --claude deja además la skill de Maker Tracker y el hook SessionStart en .claude/.",
		example:     "mt init PG --claude", run: runInit}, "claude! instala la skill y el hook de Claude Code en el repo")
	def(&command{name: "projects", group: setupGroup, usage: "mt projects", maxArgs: 0,
		summary: "Lista los proyectos de la instancia", example: "mt projects",
		run: func(e *env) error { return e.call("GET", "/api/projects", nil, nil) }})

	def(&command{name: "context", group: readGroup, usage: "mt context [--hook]", maxArgs: 0,
		summary:     "Brief, últimas decisiones, hito actual y lo que está en curso: el onboarding del agente",
		description: "Con --hook (el hook SessionStart de mt init --claude) nunca falla: si no puede, imprime una línea con el motivo y sale con 0.",
		example:     "mt context",
		run: func(e *env) error {
			err := e.projectCall("GET", "/context", nil, nil)
			if err != nil && e.opts.has("hook") {
				if _, ok := err.(silentError); !ok {
					fmt.Fprintf(e.stdout, "Maker Tracker: sin contexto del proyecto (%s)\n", oneLine(err))
				}
				return nil
			}
			return err
		}}, "hook! modo hook: no falla nunca")
	def(&command{name: "next", group: readGroup, usage: "mt next", maxArgs: 0,
		summary: "La siguiente historia Lista y no bloqueada, entera y con el motivo", example: "mt next",
		run: func(e *env) error { return e.projectCall("GET", "/next", nil, nil) }})
	def(&command{name: "roadmap", group: readGroup, usage: "mt roadmap [--closed]", maxArgs: 0,
		summary: "El roadmap: hitos en orden con sus historias y la bandeja de ideas", example: "mt roadmap --closed",
		run: func(e *env) error {
			q := map[string]string{}
			if e.opts.has("closed") {
				q["closed"] = "true"
			}
			return e.projectCall("GET", "/roadmap", q, nil)
		}}, "closed! incluye los hitos cerrados")
	def(&command{name: "show", group: readGroup, usage: "mt show <historia>", minArgs: 1, maxArgs: 1,
		summary:     "Una historia en markdown, con frontmatter, comentarios e historial",
		description: "Es el mismo formato que acepta mt edit: mt show PG-49 > f.md, editar y mt edit PG-49 --file f.md.",
		example:     "mt show PG-49",
		run:         func(e *env) error { return e.storyCall("GET", e.arg(0), "", nil) }})
	def(&command{name: "list", group: readGroup, usage: "mt list [--state …] [--milestone …] [--label …] [--mine]", maxArgs: 0,
		summary: "Lista historias con filtros", example: "mt list --state defining --milestone M2",
		run: func(e *env) error {
			q := map[string]string{"state": e.opts.get("state"), "milestone": e.opts.get("milestone"), "label": e.opts.get("label")}
			if e.opts.has("mine") {
				q["claimed_by"] = "me"
			}
			return e.projectCall("GET", "/stories", q, nil)
		}}, "state idea | defining | ready | in_progress | done", "milestone M2, su título o inbox", "label una label", "mine! solo las tuyas")
	def(&command{name: "decisions", group: readGroup, usage: "mt decisions", maxArgs: 0,
		summary: "Todas las decisiones, de la más reciente a la más antigua", example: "mt decisions",
		run: func(e *env) error { return e.projectCall("GET", "/decisions", nil, nil) }})

	def(&command{name: "start", group: workGroup, usage: "mt start <historia>", minArgs: 1, maxArgs: 1,
		summary: "Reclama la historia y la pasa a En curso", example: "mt start PG-49",
		run: func(e *env) error { return e.storyCall("POST", e.arg(0), "/start", map[string]any{}) }})
	def(&command{name: "done", group: workGroup, usage: "mt done <historia> [--commit sha]… [--pr url]", minArgs: 1, maxArgs: 1,
		summary: "La pasa a Hecha enlazando sus commits o su PR", example: "mt done PG-49 --commit 4b9781e --commit d92b53f",
		run: func(e *env) error {
			body := map[string]any{"commits": e.opts.all("commit")}
			return e.storyCall("POST", e.arg(0), "/done", optional(body, e, "pr"))
		}}, "commit* sha de un commit (se puede repetir)", "pr url de la PR")
	def(&command{name: "release", group: workGroup, usage: "mt release <historia> --reason \"…\"", minArgs: 1, maxArgs: 1,
		summary: "La suelta: vuelve a Lista y sin dueño", example: "mt release PG-49 --reason \"Falta decidir el formato de las variables\"",
		run: func(e *env) error {
			return e.storyCall("POST", e.arg(0), "/release", optional(map[string]any{}, e, "reason"))
		}}, "reason por qué la sueltas")
	def(&command{name: "comment", group: workGroup, usage: "mt comment <historia> \"…\"", minArgs: 2, maxArgs: 2,
		summary: "Comenta en la historia (markdown; \"-\" lee de la entrada estándar)", example: "mt comment PG-49 \"¿Las variables admiten formato de fecha?\"",
		run: func(e *env) error {
			body := e.arg(1)
			if body == "-" {
				var err error
				if body, err = readFileArg(e, "-"); err != nil {
					return err
				}
			}
			return e.storyCall("POST", e.arg(0), "/comments", map[string]any{"body": body})
		}})
	def(&command{name: "decide", group: workGroup, usage: "mt decide \"…\" --why \"…\" [--story PG-49] [--supersedes D-9]", minArgs: 1, maxArgs: 1,
		summary: "Registra una decisión y su porqué", example: "mt decide \"Plantillas en JSON\" --why \"No hace falta otra tabla\" --story PG-49",
		run: func(e *env) error {
			body := optional(map[string]any{"title": e.arg(0), "body": e.opts.get("why")}, e, "story", "supersedes")
			return e.projectCall("POST", "/decisions", nil, body)
		}}, "why el porqué", "story la historia de la que sale", "supersedes la decisión que sustituye (D-9)")

	def(&command{name: "create", group: defineGroup, usage: "mt create [\"Título\"] [--milestone M2] [--state …] [--file f.md]", maxArgs: 1,
		summary:     "Crea una historia: con título o con un fichero en el formato de mt show",
		description: "Sin --state nace como Idea y sin --milestone va a la bandeja de ideas. Las opciones mandan sobre el fichero.",
		example:     "mt create \"Plantillas compartidas\" --milestone M3 --state defining",
		run: func(e *env) error {
			body := optional(map[string]any{}, e, "milestone", "state")
			if e.arg(0) != "" {
				body["title"] = e.arg(0)
			}
			if e.opts.has("file") {
				text, err := readFileArg(e, e.opts.get("file"))
				if err != nil {
					return err
				}
				body["markdown"] = text
			} else if e.arg(0) == "" {
				return usageErrorf("falta el título o --file")
			}
			return e.projectCall("POST", "/stories", nil, body)
		}}, "milestone M2, su título o inbox", "state idea | defining | ready", "file fichero con la historia (- para la entrada estándar)")
	def(&command{name: "edit", group: defineGroup, usage: "mt edit <historia> --file f.md", minArgs: 1, maxArgs: 1,
		summary:     "Edita título, cuerpo y propiedades desde un fichero en el formato de mt show",
		description: "El estado y el hito no se cambian editando: usa mt move y mt reorder.",
		example:     "mt show PG-49 > f.md && $EDITOR f.md && mt edit PG-49 --file f.md",
		run: func(e *env) error {
			if !e.opts.has("file") {
				return usageErrorf("falta --file (usa - para la entrada estándar)")
			}
			text, err := readFileArg(e, e.opts.get("file"))
			if err != nil {
				return err
			}
			return e.storyCall("PATCH", e.arg(0), "", map[string]any{"markdown": text})
		}}, "file fichero con la historia (- para la entrada estándar)")
	def(&command{name: "move", group: defineGroup, usage: "mt move <historia> <estado>", minArgs: 2, maxArgs: 2,
		summary: "Cambia el estado: idea, defining, ready, in_progress o done", example: "mt move PG-51 ready",
		run: func(e *env) error {
			return e.storyCall("POST", e.arg(0), "/move", map[string]any{"state": e.arg(1)})
		}})
	def(&command{name: "reorder", group: defineGroup, usage: "mt reorder <historia> [--position n] [--milestone M3] --reason \"…\"", minArgs: 1, maxArgs: 1,
		summary: "Ordena la historia en su hito (desde 1) o la lleva a otro", example: "mt reorder PG-50 --position 1 --reason \"La piden los usuarios beta\"",
		run: func(e *env) error {
			body := optional(map[string]any{}, e, "milestone", "reason")
			if e.opts.has("position") {
				n, err := strconv.Atoi(e.opts.get("position"))
				if err != nil {
					return usageErrorf("--position tiene que ser un número")
				}
				body["position"] = n
			}
			return e.storyCall("POST", e.arg(0), "/reorder", body)
		}}, "position posición desde 1", "milestone M3, su título o inbox", "reason por qué (obligatorio para agentes)")
	def(&command{name: "brief", group: defineGroup, usage: "mt brief [--file f.md]", maxArgs: 0,
		summary: "Muestra el brief o, con --file, lo sustituye", example: "mt brief > brief.md && mt brief --file brief.md",
		run: func(e *env) error {
			if !e.opts.has("file") {
				return e.projectCall("GET", "/brief", nil, nil)
			}
			text, err := readFileArg(e, e.opts.get("file"))
			if err != nil {
				return err
			}
			return e.projectCall("PUT", "/brief", nil, map[string]any{"markdown": text})
		}}, "file fichero con el brief (- para la entrada estándar)")

	milestone := func(e *env, suffix string, body map[string]any) error {
		return e.projectCall(map[bool]string{true: "PATCH", false: "POST"}[suffix == ""], "/milestones/"+url.PathEscape(e.arg(0))+suffix, nil, body)
	}
	def(&command{name: "milestone create", group: defineGroup, usage: "mt milestone create \"Título\" [--goal \"…\"]", minArgs: 1, maxArgs: 1,
		summary: "Crea un hito al final del roadmap", example: "mt milestone create \"Equipos\" --goal \"Varias personas en la misma cuenta\"",
		run: func(e *env) error {
			return e.projectCall("POST", "/milestones", nil, optional(map[string]any{"title": e.arg(0)}, e, "goal"))
		}}, "goal objetivo del hito (markdown)")
	def(&command{name: "milestone edit", group: defineGroup, usage: "mt milestone edit <hito> [--title …] [--goal …]", minArgs: 1, maxArgs: 1,
		summary: "Edita el título o el objetivo de un hito (M2 o su título)", example: "mt milestone edit M2 --goal \"Programar una semana en 10 minutos\"",
		run: func(e *env) error { return milestone(e, "", optional(map[string]any{}, e, "title", "goal")) }},
		"title nuevo título", "goal nuevo objetivo (markdown)")
	def(&command{name: "milestone reorder", group: defineGroup, usage: "mt milestone reorder <hito> --position n --reason \"…\"", minArgs: 1, maxArgs: 1,
		summary: "Cambia el orden de un hito (y con él su código)", example: "mt milestone reorder M4 --position 3 --reason \"Equipos antes que Analítica\"",
		run: func(e *env) error {
			n, err := strconv.Atoi(e.opts.get("position"))
			if err != nil {
				return usageErrorf("--position tiene que ser un número")
			}
			return milestone(e, "/reorder", optional(map[string]any{"position": n}, e, "reason"))
		}}, "position posición desde 1", "reason por qué (obligatorio para agentes)")
	def(&command{name: "milestone close", group: defineGroup, usage: "mt milestone close <hito>", minArgs: 1, maxArgs: 1,
		summary: "Cierra un hito", example: "mt milestone close M2",
		run: func(e *env) error { return milestone(e, "/close", map[string]any{}) }})
	def(&command{name: "milestone reopen", group: defineGroup, usage: "mt milestone reopen <hito>", minArgs: 1, maxArgs: 1,
		summary: "Reabre un hito", example: "mt milestone reopen M2",
		run: func(e *env) error { return milestone(e, "/reopen", map[string]any{}) }})
}

func oneLine(err error) string {
	if apiErr, ok := err.(*APIError); ok {
		return apiErr.Code + ": " + apiErr.Message
	}
	return strings.Join(strings.Fields(err.Error()), " ")
}

// mt setup <url> <token>: comprueba la API y el token antes de guardarlos.
func runSetup(e *env) error {
	cfg := Config{URL: strings.TrimRight(e.arg(0), "/"), Token: e.arg(1)}
	if !strings.HasPrefix(cfg.URL, "http://") && !strings.HasPrefix(cfg.URL, "https://") {
		return usageErrorf("la url tiene que empezar por http:// o https://")
	}
	e.client = newClient(cfg)

	root, err := e.client.Do("GET", "/api", nil, nil)
	if err != nil {
		return err
	}
	if !root.OK {
		return root.Error
	}
	projects, err := e.client.Do("GET", "/api/projects", nil, nil)
	if err != nil {
		return err
	}
	if !projects.OK {
		return projects.Error
	}
	path, err := saveConfig(cfg)
	if err != nil {
		return err
	}

	var data struct {
		Actor string `json:"actor"`
	}
	_ = jsonUnmarshal(projects.Data, &data)
	fmt.Fprintf(e.stdout, "Conectado a %s como %s. Guardado en %s.\n\n%s\n", cfg.URL, data.Actor, path, strings.TrimSpace(projects.Markdown()))
	if os.Getenv("MT_URL") != "" || os.Getenv("MT_TOKEN") != "" {
		fmt.Fprintln(e.stdout, "\nAviso: MT_URL o MT_TOKEN están definidas y tienen prioridad sobre este fichero.")
	}
	fmt.Fprintln(e.stdout, "\nSiguiente:\n  mt init <CLAVE> en la raíz del repo del proyecto")
	return nil
}

// mt init PG [--claude]: deja .mt en el directorio actual.
func runInit(e *env) error {
	key := strings.ToUpper(e.arg(0))
	if !regexp.MustCompile(`^[A-Z]{2,5}$`).MatchString(key) {
		return usageErrorf("%q no es una clave de proyecto (de 2 a 5 letras, como PG)", e.arg(0))
	}

	// Si hay instancia configurada, comprueba que el proyecto existe.
	if e.cfg.URL != "" {
		projects, err := e.client.Do("GET", "/api/projects", nil, nil)
		switch {
		case err != nil:
			fmt.Fprintf(e.stderr, "Aviso: no he podido comprobar que %s existe (%v)\n", key, err)
		case !projects.OK:
			return projects.Error
		default:
			var data struct {
				Projects []struct{ Key string } `json:"projects"`
			}
			_ = jsonUnmarshal(projects.Data, &data)
			found := false
			for _, p := range data.Projects {
				found = found || p.Key == key
			}
			if !found {
				return &APIError{Code: "NOT_FOUND", Message: "No existe el proyecto " + key, Hint: "Los proyectos están en mt projects"}
			}
		}
	}

	dir, err := os.Getwd()
	if err != nil {
		return err
	}
	path := filepath.Join(dir, ProjectFile)
	if err := os.WriteFile(path, []byte("# Proyecto de Maker Tracker de este repo (mt)\nproject: "+key+"\n"), 0o644); err != nil {
		return err
	}
	fmt.Fprintf(e.stdout, "%s: project: %s\n", path, key)

	if e.opts.has("claude") {
		if err := installClaude(e, dir); err != nil {
			return err
		}
	}
	fmt.Fprintln(e.stdout, "\nSiguiente:\n  mt context\n  mt next")
	return nil
}
