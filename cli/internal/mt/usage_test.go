package mt

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestReadSessionUsageDedupesAndAddsSubagents(t *testing.T) {
	session, err := readSessionUsage("testdata/abc123.jsonl")
	if err != nil {
		t.Fatal(err)
	}
	if session.SessionID != "abc123" {
		t.Errorf("session id = %q", session.SessionID)
	}
	want := map[string]modelUsage{
		// msg_1 cuenta una vez (su última línea) y msg_s1 viene del subagente.
		"claude-opus-5-5":   {Model: "claude-opus-5-5", Input: 9, Output: 185 + 35, CacheRead: 150, CacheWrite5m: 100, CacheWrite1h: 200},
		"claude-sonnet-5-5": {Model: "claude-sonnet-5-5", Input: 5, Output: 20, CacheWrite5m: 40},
	}
	if len(session.Models) != len(want) {
		t.Fatalf("models = %+v", session.Models)
	}
	for _, got := range session.Models {
		if got != want[got.Model] {
			t.Errorf("%s = %+v, want %+v", got.Model, got, want[got.Model])
		}
	}
	if got := session.StartedAt.Format("15:04:05"); got != "10:00:00" {
		t.Errorf("started = %s", got)
	}
	if got := session.EndedAt.Format("15:04:05"); got != "10:09:00" {
		t.Errorf("ended = %s", got)
	}
}

func TestReadSessionUsageMissingTranscript(t *testing.T) {
	if _, err := readSessionUsage("testdata/nope.jsonl"); err == nil {
		t.Fatal("expected an error")
	}
}

func TestAddHookIsIdempotentAndKeepsTheRest(t *testing.T) {
	path := filepath.Join(t.TempDir(), ".claude", "settings.json")
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		t.Fatal(err)
	}
	// Un repo que ya tenía mt init --claude (solo SessionStart) y otras cosas.
	old := `{"model":"opus","hooks":{"SessionStart":[{"hooks":[{"type":"command","command":"mt context --hook"}]}]}}`
	if err := os.WriteFile(path, []byte(old), 0o644); err != nil {
		t.Fatal(err)
	}
	for i, wantAdded := range []bool{false, true, false, false} {
		h := claudeHooks[0]
		if i%2 == 1 || i == 3 {
			h = claudeHooks[1]
		}
		added, err := addHook(path, h)
		if err != nil || added != wantAdded {
			t.Fatalf("call %d: added=%v err=%v, want added=%v", i, added, err, wantAdded)
		}
	}
	data, _ := os.ReadFile(path)
	text := string(data)
	for _, want := range []string{`"model": "opus"`, `"SessionEnd"`, `"timeout": 10`, "mt usage --hook"} {
		if !strings.Contains(text, want) {
			t.Errorf("settings.json lacks %s:\n%s", want, text)
		}
	}
	if strings.Count(text, "mt context") != 1 || strings.Count(text, "mt usage") != 1 {
		t.Errorf("a hook got duplicated:\n%s", text)
	}
}
