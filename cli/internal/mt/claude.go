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
const HookCommand = `command -v mt >/dev/null 2>&1 && mt context --hook || echo "Maker Tracker: sin contexto (mt no está instalado o no está en el PATH)"`

// installClaude deja la skill en .claude/skills/maker-tracker/ y el hook en
// .claude/settings.json del repo. Repetirlo no duplica nada.
func installClaude(e *env, dir string) error {
	skillPath := filepath.Join(dir, ".claude", "skills", "maker-tracker", "SKILL.md")
	if err := os.MkdirAll(filepath.Dir(skillPath), 0o755); err != nil {
		return err
	}
	current, _ := os.ReadFile(skillPath)
	switch {
	case bytes.Equal(current, skill.Markdown):
		fmt.Fprintf(e.stdout, "%s: ya estaba al día\n", skillPath)
	default:
		if err := os.WriteFile(skillPath, skill.Markdown, 0o644); err != nil {
			return err
		}
		fmt.Fprintf(e.stdout, "%s: skill maker-tracker\n", skillPath)
	}

	settingsPath := filepath.Join(dir, ".claude", "settings.json")
	added, err := addSessionStartHook(settingsPath)
	if err != nil {
		return err
	}
	if added {
		fmt.Fprintf(e.stdout, "%s: hook SessionStart con mt context\n", settingsPath)
	} else {
		fmt.Fprintf(e.stdout, "%s: el hook ya estaba\n", settingsPath)
	}
	return nil
}

// addSessionStartHook añade el hook sin tocar el resto de settings.json. Si
// ya hay un hook que ejecuta mt context, no hace nada.
func addSessionStartHook(path string) (bool, error) {
	settings := map[string]any{}
	data, err := os.ReadFile(path)
	if err != nil && !errors.Is(err, os.ErrNotExist) {
		return false, err
	}
	if len(bytes.TrimSpace(data)) > 0 {
		if err := json.Unmarshal(data, &settings); err != nil {
			return false, fmt.Errorf("%s no es JSON válido: %v", path, err)
		}
	}

	hooks, _ := settings["hooks"].(map[string]any)
	if hooks == nil {
		hooks = map[string]any{}
	}
	groups, _ := hooks["SessionStart"].([]any)
	for _, group := range groups {
		entries, _ := group.(map[string]any)["hooks"].([]any)
		for _, entry := range entries {
			if command, _ := entry.(map[string]any)["command"].(string); strings.Contains(command, "mt context") {
				return false, nil
			}
		}
	}

	groups = append(groups, map[string]any{
		"hooks": []any{map[string]any{"type": "command", "command": HookCommand}},
	})
	hooks["SessionStart"] = groups
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
