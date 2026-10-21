package mt

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/franwer-ranger/maker_tracker/cli/skill"
)

// HookCommand es el hook SessionStart: inyecta mt context al empezar la
// sesión. Con --hook, mt no falla nunca; si mt no está instalado, lo dice.
const HookCommand = `command -v mt >/dev/null 2>&1 && mt context --hook || echo "Maker Tracker: no project context (mt is not installed or not in the PATH)"`

type skillState int

const (
	skillMissing skillState = iota
	skillOutdated
	skillCurrent
)

// globalSkillPath: ~/.claude/skills/<nombre>/SKILL.md, o bajo
// $CLAUDE_CONFIG_DIR si está definida (como hace Claude Code).
func globalSkillPath(name string) (string, error) {
	dir := os.Getenv("CLAUDE_CONFIG_DIR")
	if dir == "" {
		home, err := os.UserHomeDir()
		if err != nil {
			return "", err
		}
		dir = filepath.Join(home, ".claude")
	}
	return filepath.Join(dir, "skills", name, "SKILL.md"), nil
}

// globalSkillState dice si la skill global está, y si es la de este mt.
func globalSkillState(s skill.Skill) (skillState, string) {
	path, err := globalSkillPath(s.Name)
	if err != nil {
		return skillMissing, ""
	}
	current, err := os.ReadFile(path)
	switch {
	case err != nil:
		return skillMissing, path
	case bytes.Equal(current, s.Content):
		return skillCurrent, path
	default:
		return skillOutdated, path
	}
}

// allSkillsCurrent: todas las skills globales están y son las de este mt.
func allSkillsCurrent() bool {
	for _, s := range skill.All() {
		if state, _ := globalSkillState(s); state != skillCurrent {
			return false
		}
	}
	return true
}

// writeSkill deja la skill en path y dice qué ha hecho.
func writeSkill(e *env, s skill.Skill, path string) error {
	current, err := os.ReadFile(path)
	if err == nil && bytes.Equal(current, s.Content) {
		fmt.Fprintf(e.stdout, "%s: already up to date\n", path)
		return nil
	}
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		return err
	}
	if err := os.WriteFile(path, s.Content, 0o644); err != nil {
		return err
	}
	verb := "installed"
	if err == nil {
		verb = "updated"
	}
	fmt.Fprintf(e.stdout, "%s: %s skill %s\n", path, s.Name, verb)
	return nil
}

// mt skill install: las skills globales (maker-tracker y daily), para que un
// agente conozca Maker Tracker en cualquier carpeta.
func runSkillInstall(e *env) error {
	for _, s := range skill.All() {
		path, err := globalSkillPath(s.Name)
		if err != nil {
			return err
		}
		if err := writeSkill(e, s, path); err != nil {
			return err
		}
	}
	next := []string{"mt init <KEY> --claude   (at the root of the project's repo)"}
	if e.cfg.URL == "" {
		next = []string{"mt setup <url> <token>"}
	}
	printFooter(e.stdout, nil, next)
	return nil
}

// hook es un hook que mt init --claude deja en .claude/settings.json: el evento
// donde va, la marca por la que se reconoce (si ya hay uno que la lleva, no se
// duplica), su comando y el timeout en segundos (0: el de Claude Code).
type hook struct {
	event, marker, command string
	timeout                int
}

var claudeHooks = []hook{
	{event: "SessionStart", marker: "mt context", command: HookCommand},
	{event: "SessionEnd", marker: "mt usage", command: HookUsageCommand, timeout: hookUsageTimeout},
}

// installClaude deja el hook en .claude/settings.json del repo y, de cada
// skill que no esté global, la skill en .claude/skills/<nombre>/. Repetirlo no
// duplica nada. Devuelve un aviso por cada skill global desfasada.
func installClaude(e *env, dir string) ([]string, error) {
	var warnings []string
	for _, s := range skill.All() {
		switch state, path := globalSkillState(s); state {
		case skillMissing:
			if err := writeSkill(e, s, filepath.Join(dir, ".claude", "skills", s.Name, "SKILL.md")); err != nil {
				return nil, err
			}
		case skillOutdated:
			warnings = append(warnings, fmt.Sprintf("the global skill in %s is not this mt's version: update it with mt skill install.", path))
		default:
			fmt.Fprintf(e.stdout, "%s: using the global skill\n", path)
		}
	}

	settingsPath := filepath.Join(dir, ".claude", "settings.json")
	for _, h := range claudeHooks {
		added, err := addHook(settingsPath, h)
		if err != nil {
			return nil, err
		}
		if added {
			fmt.Fprintf(e.stdout, "%s: %s hook with %s\n", settingsPath, h.event, h.marker)
		} else {
			fmt.Fprintf(e.stdout, "%s: the %s hook was already there\n", settingsPath, h.event)
		}
	}
	return warnings, nil
}

// addHook añade el hook sin tocar el resto de settings.json. Si ya hay uno en
// ese evento cuyo comando lleva la marca, no hace nada.
func addHook(path string, h hook) (bool, error) {
	settings := map[string]any{}
	data, err := os.ReadFile(path)
	if err != nil && !errors.Is(err, os.ErrNotExist) {
		return false, err
	}
	if len(bytes.TrimSpace(data)) > 0 {
		if err := json.Unmarshal(data, &settings); err != nil {
			return false, fmt.Errorf("%s is not valid JSON: %v", path, err)
		}
	}

	hooks, _ := settings["hooks"].(map[string]any)
	if hooks == nil {
		hooks = map[string]any{}
	}
	groups, _ := hooks[h.event].([]any)
	for _, group := range groups {
		entries, _ := group.(map[string]any)["hooks"].([]any)
		for _, entry := range entries {
			if command, _ := entry.(map[string]any)["command"].(string); strings.Contains(command, h.marker) {
				return false, nil
			}
		}
	}

	entry := map[string]any{"type": "command", "command": h.command}
	if h.timeout > 0 {
		entry["timeout"] = h.timeout
	}
	groups = append(groups, map[string]any{"hooks": []any{entry}})
	hooks[h.event] = groups
	settings["hooks"] = hooks

	var out bytes.Buffer
	encoder := json.NewEncoder(&out)
	encoder.SetEscapeHTML(false) // que el comando se lea tal cual (>, &)
	encoder.SetIndent("", "  ")
	if err := encoder.Encode(settings); err != nil {
		return false, err
	}
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		return false, err
	}
	return true, os.WriteFile(path, out.Bytes(), 0o644)
}
