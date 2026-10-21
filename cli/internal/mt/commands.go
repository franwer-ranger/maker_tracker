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
		return "", usageHint("run mt init PG at the root of the repo, use --project PG or name the story as PG-49.", "no project here.")
	}
	return key, nil
}

var referencePattern = regexp.MustCompile(`^(?i:([a-z]{2,5})-)?(\d+)$`)

// storyPath: /api/projects/PG/stories/49 a partir de PG-49 o 49.
func (e *env) storyPath(reference string) (string, error) {
	m := referencePattern.FindStringSubmatch(strings.TrimPrefix(reference, "#"))
	if m == nil {
		return "", usageHint("use PG-49 or 49.", "%q is not a story.", reference)
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
	const setupGroup, readGroup, workGroup, defineGroup = "Set up", "Read", "Work on a story", "Define the product"

	def(&command{name: "setup", group: setupGroup, usage: "mt setup <url> <token>", minArgs: 2, maxArgs: 2,
		summary:     "Saves the instance and the token in ~/.config/mt/config and checks they work",
		description: "Create the token on the server with bin/rails \"mt:token[your-name]\". MT_URL and MT_TOKEN take precedence over the file.",
		example:     "mt setup https://tower.your-tailnet.ts.net mt_…", run: runSetup})
	def(&command{name: "init", group: setupGroup, usage: "mt init <KEY> [--claude]", minArgs: 1, maxArgs: 1,
		summary:     "Creates .mt with the project in the current directory (the root of the repo)",
		description: "mt looks for .mt upwards from the current directory. With --claude it also adds the SessionStart (mt context) and SessionEnd (mt usage, the cost of the session) hooks to .claude/settings.json and, if the skill is not installed globally (mt skill install), the skills (maker-tracker and daily) to .claude/skills/.",
		example:     "mt init PG --claude", run: runInit}, "claude! adds the Claude Code hook (and the skill, if it is not installed globally) to the repo")
	def(&command{name: "project create", group: setupGroup, usage: "mt project create \"Name\" --key <KEY>", minArgs: 1, maxArgs: 1,
		summary:     "Creates a project, with the brief template",
		description: "The key has 2 to 5 letters and names its stories (PG-49). Then mt init <KEY> --claude at the root of its repo and mt brief --file f.md.",
		example:     "mt project create \"Postgram\" --key PG",
		run: func(e *env) error {
			if !e.opts.has("key") {
				return usageHint("mt project create \"Postgram\" --key PG", "missing --key.")
			}
			return e.call("POST", "/api/projects", nil, map[string]any{"name": e.arg(0), "key": strings.ToUpper(e.opts.get("key"))})
		}}, "key 2 to 5 letters, like PG")
	def(&command{name: "skill install", group: setupGroup, usage: "mt skill install", maxArgs: 0,
		summary:     "Installs (or updates) the Maker Tracker skills (maker-tracker and daily) for Claude Code in ~/.claude/skills/",
		description: "With the skill installed globally, an agent knows Maker Tracker in any folder, also in a repo that is not in Maker Tracker yet. Uses $CLAUDE_CONFIG_DIR if it is set.",
		example:     "mt skill install", run: runSkillInstall})
	def(&command{name: "projects", group: setupGroup, usage: "mt projects", maxArgs: 0,
		summary: "Lists the projects of the instance", example: "mt projects",
		run: func(e *env) error { return e.call("GET", "/api/projects", nil, nil) }})

	def(&command{name: "context", group: readGroup, usage: "mt context [--hook]", maxArgs: 0,
		summary:     "Brief, decisions in force, current milestone and what is in progress: the agent's onboarding",
		description: "With --hook (the SessionStart hook from mt init --claude) it never fails: if it can't, it prints one line saying why and exits with 0.",
		example:     "mt context",
		run: func(e *env) error {
			err := e.projectCall("GET", "/context", nil, nil)
			if err != nil && e.opts.has("hook") {
				if _, ok := err.(silentError); !ok {
					fmt.Fprintf(e.stdout, "Maker Tracker: no project context (%s)\n", oneLine(err))
				}
				return nil
			}
			return err
		}}, "hook! hook mode: never fails")
	def(&command{name: "usage", group: workGroup, usage: "mt usage <transcript.jsonl> [--story 49] | mt usage --hook", maxArgs: 1,
		summary:     "Reports the tokens and the estimated cost of a Claude Code session to the story it worked on",
		description: "Reads the transcript (and its subagents), adds up the tokens per model and the server prices them. The story is the last one you started that was in progress during the session, unless you pass --story. The hook (SessionEnd, from mt init --claude) runs it with --hook, which never fails or prints anything. By hand it recovers a session whose hook did not fire; it is idempotent: reporting the same session again only adds what is new.",
		example:     "mt usage ~/.claude/projects/-Users-me-code-app/0b447df5.jsonl",
		run:         runUsage}, "hook! hook mode (reads the SessionEnd JSON from stdin): never fails or prints", "story the story number, instead of the one the server picks")
	def(&command{name: "next", group: readGroup, usage: "mt next", maxArgs: 0,
		summary: "The next ready, unblocked story, whole and with why", example: "mt next",
		run: func(e *env) error { return e.projectCall("GET", "/next", nil, nil) }})
	def(&command{name: "daily", group: readGroup, usage: "mt daily [--since date]", maxArgs: 0,
		summary:     "The project's daily: what happened, in progress, blocked, waiting for the human and what is next",
		description: "Counts from your last daily in this project (another actor's daily does not move yours), or from --since (2026-10-15 or \"2026-10-15 22:40\"). Without a previous daily it shows the last 7 days. Running it records your daily, so the next one starts here. It works in a project with no history yet.",
		example:     "mt daily",
		run: func(e *env) error {
			return e.projectCall("POST", "/daily", nil, optional(map[string]any{}, e, "since"))
		}}, "since count from this date, not from your last daily")
	def(&command{name: "daily idea", group: workGroup, usage: "mt daily idea \"…\" [--why \"…\"]", minArgs: 1, maxArgs: 1,
		summary:     "Proposes an evolutionary as an idea in the inbox (up to 3 per daily)",
		description: "For what the daily suggests: it goes to the inbox as an idea, never to the roadmap, and needs you to have run mt daily first. Whoever defines the product decides what happens next.",
		example:     "mt daily idea \"Exportar el calendario a iCal\" --why \"Hay un TODO en calendar.rb y los makers lo usan en Google Calendar\"",
		run: func(e *env) error {
			return e.projectCall("POST", "/daily/ideas", nil, optional(map[string]any{"title": e.arg(0)}, e, "why"))
		}}, "why the context of the idea (markdown)")
	def(&command{name: "roadmap", group: readGroup, usage: "mt roadmap [--closed]", maxArgs: 0,
		summary: "The roadmap: milestones in order with their stories, and the inbox", example: "mt roadmap --closed",
		run: func(e *env) error {
			q := map[string]string{}
			if e.opts.has("closed") {
				q["closed"] = "true"
			}
			return e.projectCall("GET", "/roadmap", q, nil)
		}}, "closed! includes closed milestones")
	def(&command{name: "show", group: readGroup, usage: "mt show <story>", minArgs: 1, maxArgs: 1,
		summary:     "A story as markdown, with frontmatter, comments and history",
		description: "It is the format mt edit takes: mt show PG-49 > f.md, edit it and mt edit PG-49 --file f.md.",
		example:     "mt show PG-49",
		run:         func(e *env) error { return e.storyCall("GET", e.arg(0), "", nil) }})
	def(&command{name: "list", group: readGroup, usage: "mt list [--state …] [--milestone …] [--label …] [--mine]", maxArgs: 0,
		summary: "Lists stories with filters", example: "mt list --state defining --milestone M2",
		run: func(e *env) error {
			q := map[string]string{"state": e.opts.get("state"), "milestone": e.opts.get("milestone"), "label": e.opts.get("label")}
			if e.opts.has("mine") {
				q["claimed_by"] = "me"
			}
			return e.projectCall("GET", "/stories", q, nil)
		}}, "state idea | defining | ready | in_progress | done", "milestone M2, its title or inbox", "label a label", "mine! only yours")
	def(&command{name: "questions", group: readGroup, usage: "mt questions [--project PG]", maxArgs: 0,
		summary:     "Open questions of all the projects, with how long they have been waiting",
		description: "Across all the projects, not only the one in .mt, unless you pass --project.",
		example:     "mt questions",
		run: func(e *env) error {
			return e.call("GET", "/api/questions", map[string]string{"project": e.opts.get("project")}, nil)
		}})
	def(&command{name: "qa", group: workGroup, usage: "mt qa [<story> ok|fail] [--note \"…\"] [--project PG]", maxArgs: 2,
		summary:     "What is done and not tested yet (no arguments), or passes/fails a story's QA",
		description: "Without arguments it lists, across all the projects (or one with --project), the stories done and still waiting for the person to test them, with their criteria and where to test (the \"Dónde se prueba\" line of the brief). Only a person passes or fails: ok closes it; fail needs --note and creates a story in defining in the same milestone, linked to this one. It never blocks or reopens the story.",
		example:     "mt qa PG-49 fail --note \"The variable is not replaced in the preview\"",
		run: func(e *env) error {
			if e.arg(0) == "" {
				return e.call("GET", "/api/qa", map[string]string{"project": e.opts.get("project")}, nil)
			}
			result := e.arg(1)
			if result != "ok" && result != "fail" {
				return usageHint("mt qa PG-49 ok [--note \"…\"] or mt qa PG-49 fail --note \"what fails\".", "say ok or fail after the story.")
			}
			body := optional(map[string]any{"result": result}, e, "note")
			return e.storyCall("POST", e.arg(0), "/qa", body)
		}}, "note what you saw (required with fail)")
	def(&command{name: "decisions", group: readGroup, usage: "mt decisions", maxArgs: 0,
		summary: "All decisions, newest first", example: "mt decisions",
		run: func(e *env) error { return e.projectCall("GET", "/decisions", nil, nil) }})

	def(&command{name: "start", group: workGroup, usage: "mt start <story>", minArgs: 1, maxArgs: 1,
		summary: "Claims the story and moves it to in progress", example: "mt start PG-49",
		run: func(e *env) error { return e.storyCall("POST", e.arg(0), "/start", map[string]any{}) }})
	def(&command{name: "done", group: workGroup, usage: "mt done <story> [--commit sha]… [--pr url]", minArgs: 1, maxArgs: 1,
		summary: "Moves it to done, linking its commits or PR", example: "mt done PG-49 --commit 4f3e2a1 --pr https://github.com/acme/postgram/pull/63",
		run: func(e *env) error {
			body := map[string]any{"commits": e.opts.all("commit")}
			return e.storyCall("POST", e.arg(0), "/done", optional(body, e, "pr"))
		}}, "commit* a commit sha (can be repeated)", "pr the PR url")
	def(&command{name: "release", group: workGroup, usage: "mt release <story> --reason \"…\"", minArgs: 1, maxArgs: 1,
		summary: "Lets it go: back to ready, unclaimed", example: "mt release PG-49 --reason \"The variable format is still undecided\"",
		run: func(e *env) error {
			return e.storyCall("POST", e.arg(0), "/release", optional(map[string]any{}, e, "reason"))
		}}, "reason why you release it")
	def(&command{name: "comment", group: workGroup, usage: "mt comment <story> \"…\"", minArgs: 2, maxArgs: 2,
		summary: "Comments on the story (markdown; \"-\" reads from standard input)", example: "mt comment PG-49 \"Do the variables take a date format?\"",
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
	def(&command{name: "ask", group: workGroup, usage: "mt ask <story> \"…\" --option \"…\" --option \"…\" [--recommend n] [--context \"…\"] [--reversible] [--no-bloqueante]", minArgs: 2, maxArgs: 2,
		summary:     "Asks a question with its options and your recommendation, instead of a comment",
		description: "It blocks by default: if the story was yours it lets it go, and nobody picks it up until the question is answered. With --no-bloqueante it does not block: you carry on with the recommended option (--recommend is then required) unless it is answered otherwise. Without --reversible the question does not say whether it can be undone.",
		example:     "mt ask PG-49 \"What if a variable has no value?\" --option \"Drop it\" --option \"Warn first\" --recommend 2 --reversible",
		run: func(e *env) error {
			body := map[string]any{"title": e.arg(1), "options": e.opts.all("option")}
			if e.opts.has("recommend") {
				n, err := strconv.Atoi(e.opts.get("recommend"))
				if err != nil {
					return usageErrorf("--recommend must be a number.")
				}
				body["recommended"] = n
			}
			if e.opts.has("reversible") {
				body["reversible"] = true
			}
			if e.opts.has("no-bloqueante") {
				body["blocking"] = false
			}
			return e.storyCall("POST", e.arg(0), "/questions", optional(body, e, "context"))
		}}, "option* an option (repeat it, at least 2)", "recommend the number of the recommended option (from 1)", "context why you ask (markdown)",
		"reversible! the decision can be undone", "no-bloqueante! it does not block: you carry on with the recommended option")
	def(&command{name: "answer", group: workGroup, usage: "mt answer <story> <option> [--note \"…\"] [--question id] [--decide]", minArgs: 1, maxArgs: 2,
		summary:     "Answers an open question with the number of an option (or with free text)",
		description: "If the story has several open questions, choose one with --question (the id from mt show, Q12 or 12). With --text \"…\" and no option you answer with your own words. With --decide it is also recorded as a decision (D-n).",
		example:     "mt answer PG-49 2 --note \"The warning names the variable\" --decide",
		run: func(e *env) error {
			body := optional(map[string]any{}, e, "note", "question", "text")
			if e.opts.has("text") && e.arg(1) == "" {
				delete(body, "note")
			} else {
				n, err := strconv.Atoi(e.arg(1))
				if err != nil {
					return usageHint("mt answer PG-49 2 (the number of the option, from 1) or mt answer PG-49 --text \"…\".", "the option must be a number.")
				}
				body["option"] = n
			}
			if e.opts.has("decide") {
				body["decide"] = true
			}
			return e.storyCall("POST", e.arg(0), "/answer", body)
		}}, "note why (markdown)", "text your own answer, if none of the options fits", "question the question's id, if there are several open (Q12 or 12)", "decide! also record it as a decision")
	def(&command{name: "decide", group: workGroup, usage: "mt decide \"…\" --why \"…\" [--story PG-49] [--supersedes D-9]", minArgs: 1, maxArgs: 1,
		summary: "Records a decision and its why", example: "mt decide \"Templates as JSON\" --why \"No need for another table\" --story PG-49",
		run: func(e *env) error {
			body := optional(map[string]any{"title": e.arg(0), "body": e.opts.get("why")}, e, "story", "supersedes")
			return e.projectCall("POST", "/decisions", nil, body)
		}}, "why the why", "story the story it comes from", "supersedes the decision it replaces (D-9)")

	def(&command{name: "create", group: defineGroup, usage: "mt create [\"Title\"] [--milestone M2] [--state …] [--number n] [--file f.md]", maxArgs: 1,
		summary:     "Creates a story: from a title or from a file in the mt show format",
		description: "Without --state it is an idea, and without --milestone it goes to the inbox. --number (or number: in the file) keeps a number if it is free, to migrate a backlog; without it, the next one. The options win over the file.",
		example:     "mt create \"Shared templates\" --milestone M3 --state defining",
		run: func(e *env) error {
			body := optional(map[string]any{}, e, "milestone", "state")
			if e.opts.has("number") {
				n, err := strconv.Atoi(strings.TrimPrefix(e.opts.get("number"), "#"))
				if err != nil {
					return usageErrorf("--number must be a number.")
				}
				body["number"] = n
			}
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
				return usageHint("mt create \"Title\" or mt create --file f.md", "missing the title or --file.")
			}
			return e.projectCall("POST", "/stories", nil, body)
		}}, "milestone M2, its title or inbox", "state idea | defining | ready", "number the story's number, if it is free", "file file with the story (- for standard input)")
	def(&command{name: "edit", group: defineGroup, usage: "mt edit <story> --file f.md", minArgs: 1, maxArgs: 1,
		summary:     "Edits title, body and properties from a file in the mt show format",
		description: "Editing does not change the state or the milestone: use mt move and mt reorder. What comes after the read-only mark is ignored.",
		example:     "mt show PG-49 > f.md && $EDITOR f.md && mt edit PG-49 --file f.md",
		run: func(e *env) error {
			if !e.opts.has("file") {
				return usageHint("mt edit PG-49 --file f.md (- for standard input)", "missing --file.")
			}
			text, err := readFileArg(e, e.opts.get("file"))
			if err != nil {
				return err
			}
			return e.storyCall("PATCH", e.arg(0), "", map[string]any{"markdown": text})
		}}, "file file with the story (- for standard input)")
	def(&command{name: "move", group: defineGroup, usage: "mt move <story> <state>", minArgs: 2, maxArgs: 2,
		summary: "Changes the state: idea, defining, ready, in_progress or done", example: "mt move PG-51 ready",
		run: func(e *env) error {
			return e.storyCall("POST", e.arg(0), "/move", map[string]any{"state": e.arg(1)})
		}})
	def(&command{name: "reorder", group: defineGroup, usage: "mt reorder <story> [--position n] [--milestone M3] --reason \"…\"", minArgs: 1, maxArgs: 1,
		summary: "Reorders the story in its milestone (from 1) or moves it to another", example: "mt reorder PG-50 --position 1 --reason \"Beta users ask for it\"",
		run: func(e *env) error {
			body := optional(map[string]any{}, e, "milestone", "reason")
			if e.opts.has("position") {
				n, err := strconv.Atoi(e.opts.get("position"))
				if err != nil {
					return usageErrorf("--position must be a number.")
				}
				body["position"] = n
			}
			return e.storyCall("POST", e.arg(0), "/reorder", body)
		}}, "position position from 1", "milestone M3, its title or inbox", "reason why (required for agents)")
	def(&command{name: "brief", group: defineGroup, usage: "mt brief [--file f.md]", maxArgs: 0,
		summary: "Shows the brief or, with --file, replaces it", example: "mt brief > brief.md && mt brief --file brief.md",
		run: func(e *env) error {
			if !e.opts.has("file") {
				return e.projectCall("GET", "/brief", nil, nil)
			}
			text, err := readFileArg(e, e.opts.get("file"))
			if err != nil {
				return err
			}
			return e.projectCall("PUT", "/brief", nil, map[string]any{"markdown": text})
		}}, "file file with the brief (- for standard input)")

	milestone := func(e *env, suffix string, body map[string]any) error {
		return e.projectCall(map[bool]string{true: "PATCH", false: "POST"}[suffix == ""], "/milestones/"+url.PathEscape(e.arg(0))+suffix, nil, body)
	}
	def(&command{name: "milestone create", group: defineGroup, usage: "mt milestone create \"Title\" [--goal \"…\"]", minArgs: 1, maxArgs: 1,
		summary: "Creates a milestone at the end of the roadmap", example: "mt milestone create \"Teams\" --goal \"Several people on the same account\"",
		run: func(e *env) error {
			return e.projectCall("POST", "/milestones", nil, optional(map[string]any{"title": e.arg(0)}, e, "goal"))
		}}, "goal the milestone's goal (markdown)")
	def(&command{name: "milestone show", group: readGroup, usage: "mt milestone show <milestone>", minArgs: 1, maxArgs: 1,
		summary: "A milestone with its version, the one to send when editing it", example: "mt milestone show M2",
		run: func(e *env) error {
			return e.projectCall("GET", "/milestones/"+url.PathEscape(e.arg(0)), nil, nil)
		}})
	def(&command{name: "milestone edit", group: defineGroup, usage: "mt milestone edit <milestone> [--title …] [--goal …] [--version n]", minArgs: 1, maxArgs: 1,
		summary:     "Edits a milestone's title or goal (M2 or its title)",
		description: "With --version (the one mt milestone show prints) it fails with CONFLICT if someone changed the milestone since, and saves nothing.",
		example:     "mt milestone edit M2 --goal \"Schedule a week in 10 minutes\" --version 3",
		run: func(e *env) error {
			body := optional(map[string]any{}, e, "title", "goal")
			if e.opts.has("version") {
				n, err := strconv.Atoi(e.opts.get("version"))
				if err != nil {
					return usageErrorf("--version must be a number.")
				}
				body["version"] = n
			}
			return milestone(e, "", body)
		}},
		"title new title", "goal new goal (markdown)", "version the version you read (mt milestone show)")
	def(&command{name: "milestone reorder", group: defineGroup, usage: "mt milestone reorder <milestone> --position n --reason \"…\"", minArgs: 1, maxArgs: 1,
		summary: "Changes a milestone's position (and with it, its code)", example: "mt milestone reorder M4 --position 3 --reason \"Teams before analytics\"",
		run: func(e *env) error {
			n, err := strconv.Atoi(e.opts.get("position"))
			if err != nil {
				return usageErrorf("--position must be a number.")
			}
			return milestone(e, "/reorder", optional(map[string]any{"position": n}, e, "reason"))
		}}, "position position from 1", "reason why (required for agents)")
	def(&command{name: "milestone close", group: defineGroup, usage: "mt milestone close <milestone>", minArgs: 1, maxArgs: 1,
		summary: "Closes a milestone", example: "mt milestone close M2",
		run: func(e *env) error { return milestone(e, "/close", map[string]any{}) }})
	def(&command{name: "milestone reopen", group: defineGroup, usage: "mt milestone reopen <milestone>", minArgs: 1, maxArgs: 1,
		summary: "Reopens a milestone", example: "mt milestone reopen M2",
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
		return usageHint("mt setup https://tower.your-tailnet.ts.net mt_…", "the url must start with http:// or https://.")
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
	fmt.Fprintf(e.stdout, "Connected to %s as %s. Saved in %s.\n\n%s\n", cfg.URL, data.Actor, path, strings.TrimSpace(projects.Markdown()))
	var warnings []string
	if os.Getenv("MT_URL") != "" || os.Getenv("MT_TOKEN") != "" {
		warnings = append(warnings, "MT_URL or MT_TOKEN are set and take precedence over this file.")
	}
	next := []string{"mt init <KEY> --claude   (at the root of the project's repo)"}
	if !allSkillsCurrent() {
		next = append([]string{"mt skill install"}, next...)
	}
	printFooter(e.stdout, warnings, next)
	return nil
}

// mt init PG [--claude]: deja .mt en el directorio actual.
func runInit(e *env) error {
	key := strings.ToUpper(e.arg(0))
	if !regexp.MustCompile(`^[A-Z]{2,5}$`).MatchString(key) {
		return usageHint("a project key has 2 to 5 letters, like PG. See them with mt projects.", "%q is not a project key.", e.arg(0))
	}

	// Si hay instancia configurada, comprueba que el proyecto existe.
	var warnings []string
	if e.cfg.URL != "" {
		projects, err := e.client.Do("GET", "/api/projects", nil, nil)
		switch {
		case err != nil:
			warnings = append(warnings, fmt.Sprintf("could not check that %s exists (%v).", key, err))
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
				return &APIError{Code: "NOT_FOUND", Message: "no project " + key + ".",
					Hint: "create it with mt project create \"Name\" --key " + key + ", or see them with mt projects."}
			}
		}
	}

	dir, err := os.Getwd()
	if err != nil {
		return err
	}
	path := filepath.Join(dir, ProjectFile)
	if err := os.WriteFile(path, []byte("# Maker Tracker project of this repo (mt)\nproject: "+key+"\n"), 0o644); err != nil {
		return err
	}
	fmt.Fprintf(e.stdout, "%s: project: %s\n", path, key)

	if e.opts.has("claude") {
		skillWarnings, err := installClaude(e, dir)
		if err != nil {
			return err
		}
		warnings = append(warnings, skillWarnings...)
	}
	printFooter(e.stdout, warnings, []string{"mt context", "mt next"})
	return nil
}
