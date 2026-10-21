package mt

import (
	"bufio"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"time"
)

// HookUsageCommand es el hook SessionEnd (MT-34): reporta el coste de la sesión
// a la historia en la que trabajó el actor. Con --hook, mt no falla nunca ni
// imprime nada.
const HookUsageCommand = `command -v mt >/dev/null 2>&1 && mt usage --hook || true`

// hookUsageTimeout: SessionEnd tiene 1,5 s por defecto; la entrada del hook lo sube a esto.
const hookUsageTimeout = 10

// modelUsage son los tokens de una sesión para un modelo (los nombres del
// cuerpo de POST /usage).
type modelUsage struct {
	Model        string `json:"model"`
	Input        int64  `json:"input"`
	Output       int64  `json:"output"`
	CacheRead    int64  `json:"cache_read"`
	CacheWrite5m int64  `json:"cache_write_5m"`
	CacheWrite1h int64  `json:"cache_write_1h"`
}

// sessionUsage es lo que se lee de un transcript y de sus subagentes.
type sessionUsage struct {
	SessionID string
	StartedAt time.Time
	EndedAt   time.Time
	Models    []modelUsage
}

// El formato del transcript de Claude Code es interno y puede cambiar: todo
// es opcional y lo que no se entiende se ignora.
type transcriptLine struct {
	Type      string `json:"type"`
	Timestamp string `json:"timestamp"`
	SessionID string `json:"sessionId"`
	Message   *struct {
		ID    string `json:"id"`
		Model string `json:"model"`
		Usage *struct {
			Input         int64 `json:"input_tokens"`
			Output        int64 `json:"output_tokens"`
			CacheRead     int64 `json:"cache_read_input_tokens"`
			CacheCreation int64 `json:"cache_creation_input_tokens"`
			Breakdown     *struct {
				Ephemeral5m int64 `json:"ephemeral_5m_input_tokens"`
				Ephemeral1h int64 `json:"ephemeral_1h_input_tokens"`
			} `json:"cache_creation"`
		} `json:"usage"`
	} `json:"message"`
}

// readSessionUsage suma el uso por modelo del transcript y de los
// `<session>/subagents/agent-*.jsonl` que cuelgan de él. Cada `message.id`
// sale varias veces en el transcript (una por bloque): cuenta la última.
func readSessionUsage(path string) (*sessionUsage, error) {
	session := &sessionUsage{SessionID: strings.TrimSuffix(filepath.Base(path), ".jsonl")}
	files := []string{path}
	subagents, _ := filepath.Glob(filepath.Join(filepath.Dir(path), session.SessionID, "subagents", "agent-*.jsonl"))
	sort.Strings(subagents)
	files = append(files, subagents...)

	byMessage := map[string]modelUsage{}
	anonymous := 0
	for i, file := range files {
		err := scanTranscript(file, func(line transcriptLine) {
			if line.Timestamp != "" {
				if t, err := time.Parse(time.RFC3339Nano, line.Timestamp); err == nil {
					if session.StartedAt.IsZero() || t.Before(session.StartedAt) {
						session.StartedAt = t
					}
					if t.After(session.EndedAt) {
						session.EndedAt = t
					}
				}
			}
			if line.Type != "assistant" || line.Message == nil || line.Message.Usage == nil || line.Message.Model == "" || line.Message.Model == "<synthetic>" {
				return
			}
			u := line.Message.Usage
			row := modelUsage{Model: line.Message.Model, Input: u.Input, Output: u.Output, CacheRead: u.CacheRead, CacheWrite5m: u.CacheCreation}
			if b := u.Breakdown; b != nil && b.Ephemeral5m+b.Ephemeral1h > 0 {
				row.CacheWrite5m, row.CacheWrite1h = b.Ephemeral5m, b.Ephemeral1h
				if rest := u.CacheCreation - b.Ephemeral5m - b.Ephemeral1h; rest > 0 {
					row.CacheWrite5m += rest
				}
			}
			id := line.Message.ID
			if id == "" {
				anonymous++
				id = fmt.Sprintf("anonymous-%d", anonymous)
			}
			byMessage[id] = row
		})
		if err != nil && i == 0 {
			return nil, err // el transcript principal es obligatorio; un subagente ilegible se salta
		}
	}

	totals := map[string]*modelUsage{}
	for _, row := range byMessage {
		t := totals[row.Model]
		if t == nil {
			t = &modelUsage{Model: row.Model}
			totals[row.Model] = t
		}
		t.Input += row.Input
		t.Output += row.Output
		t.CacheRead += row.CacheRead
		t.CacheWrite5m += row.CacheWrite5m
		t.CacheWrite1h += row.CacheWrite1h
	}
	for _, t := range totals {
		session.Models = append(session.Models, *t)
	}
	sort.Slice(session.Models, func(i, j int) bool { return session.Models[i].Model < session.Models[j].Model })
	return session, nil
}

// scanTranscript lee línea a línea (hay líneas enormes) y salta las que no son JSON.
func scanTranscript(path string, visit func(transcriptLine)) error {
	f, err := os.Open(path)
	if err != nil {
		return err
	}
	defer f.Close()
	reader := bufio.NewReaderSize(f, 1<<20)
	for {
		raw, err := reader.ReadBytes('\n')
		if len(strings.TrimSpace(string(raw))) > 0 {
			var line transcriptLine
			if json.Unmarshal(raw, &line) == nil {
				visit(line)
			}
		}
		if err == io.EOF {
			return nil
		}
		if err != nil {
			return err
		}
	}
}

// body es el cuerpo de POST /api/projects/:key/usage.
func (s *sessionUsage) body(story string) map[string]any {
	body := map[string]any{"source": "claude-code", "session_id": s.SessionID, "models": s.Models}
	if !s.StartedAt.IsZero() {
		body["started_at"] = s.StartedAt.UTC().Format(time.RFC3339)
	}
	if !s.EndedAt.IsZero() {
		body["ended_at"] = s.EndedAt.UTC().Format(time.RFC3339)
	}
	if story != "" {
		body["story"] = story
	}
	return body
}

// runUsage: mt usage <transcript.jsonl> [--story 49] | mt usage --hook.
func runUsage(e *env) error {
	if e.opts.has("hook") {
		runUsageHook(e)
		return nil
	}
	if e.arg(0) == "" {
		return usageHint("mt usage ~/.claude/projects/<project>/<session>.jsonl [--story 49], or mt usage --hook from the SessionEnd hook.", "missing the transcript.")
	}
	session, err := readSessionUsage(e.arg(0))
	if err != nil {
		return &hintedError{msg: fmt.Sprintf("cannot read the transcript: %v.", err), hint: "pass the .jsonl of the session, from ~/.claude/projects/."}
	}
	if len(session.Models) == 0 {
		return &hintedError{msg: "the transcript has no usage in it.", hint: "is it a Claude Code session transcript?"}
	}
	story := strings.TrimPrefix(strings.ToUpper(e.opts.get("story")), "#")
	return e.projectCall("POST", "/usage", nil, session.body(story))
}

// runUsageHook lee el JSON del hook SessionEnd de stdin y hace una sola
// llamada. Nunca falla ni imprime nada: sin transcript, JSON raro o sin red, sale.
func runUsageHook(e *env) {
	defer func() { _ = recover() }()
	var input struct {
		TranscriptPath string `json:"transcript_path"`
		Cwd            string `json:"cwd"`
	}
	if data, err := io.ReadAll(io.LimitReader(e.stdin, 1<<20)); err != nil || json.Unmarshal(data, &input) != nil || input.TranscriptPath == "" {
		return
	}
	dir := input.Cwd
	if dir == "" {
		dir, _ = os.Getwd()
	}
	key := strings.ToUpper(e.opts.get("project"))
	if key == "" {
		key, _, _ = findProject(dir)
	}
	if key == "" || e.cfg.URL == "" {
		return
	}
	session, err := readSessionUsage(input.TranscriptPath)
	if err != nil || len(session.Models) == 0 {
		return
	}
	e.client.HTTP = &http.Client{Timeout: (hookUsageTimeout - 2) * time.Second}
	_, _ = e.client.Do("POST", projectPath(key)+"/usage", nil, session.body(""))
}
