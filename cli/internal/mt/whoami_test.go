package mt

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

// whoamiServer responde a GET /api/projects como la instancia: good es el
// único token válido y su actor es claude (agent).
func whoamiServer(t *testing.T) *httptest.Server {
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		if r.Header.Get("Authorization") != "Bearer good" {
			w.WriteHeader(http.StatusUnauthorized)
			w.Write([]byte(`{"ok":false,"error":{"code":"UNAUTHORIZED","message":"the token is not valid.","retryable":false}}`))
			return
		}
		w.Write([]byte(`{"ok":true,"data":{"actor":"claude","actor_kind":"agent","projects":[]}}`))
	}))
	t.Cleanup(srv.Close)
	return srv
}

// runWhoamiIn ejecuta mt whoami en dir con un config temporal que apunta a url con token.
func runWhoamiIn(t *testing.T, dir, url, token string, args ...string) (string, string, int) {
	configHome := t.TempDir()
	os.MkdirAll(filepath.Join(configHome, "mt"), 0o700)
	os.WriteFile(filepath.Join(configHome, "mt", "config"), []byte("url: "+url+"\ntoken: "+token+"\n"), 0o600)
	t.Setenv("XDG_CONFIG_HOME", configHome)
	wd, _ := os.Getwd()
	if err := os.Chdir(dir); err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { os.Chdir(wd) })
	var out, errOut bytes.Buffer
	code := Main(append([]string{"whoami"}, args...), strings.NewReader(""), &out, &errOut)
	return out.String(), errOut.String(), code
}

func TestWhoamiFromFile(t *testing.T) {
	srv := whoamiServer(t)
	t.Setenv("MT_URL", "")
	t.Setenv("MT_TOKEN", "")
	out, _, code := runWhoamiIn(t, t.TempDir(), srv.URL, "good")
	if code != 0 {
		t.Fatalf("code %d", code)
	}
	for _, want := range []string{"claude (agent) at " + srv.URL, "URL from:    ", "Token from:  ", "mt/config"} {
		if !strings.Contains(out, want) {
			t.Errorf("missing %q in:\n%s", want, out)
		}
	}
	if strings.Contains(out, "environment") || strings.Contains(out, "Project:") {
		t.Errorf("no env and no .mt expected:\n%s", out)
	}
}

func TestWhoamiTokenFromEnvAndProject(t *testing.T) {
	srv := whoamiServer(t)
	repo := t.TempDir()
	os.WriteFile(filepath.Join(repo, ".mt"), []byte("project: mt\n"), 0o644)
	sub := filepath.Join(repo, "app")
	os.Mkdir(sub, 0o755)
	t.Setenv("MT_URL", "")
	t.Setenv("MT_TOKEN", "good")
	out, _, code := runWhoamiIn(t, sub, srv.URL, "stale")
	if code != 0 {
		t.Fatalf("code %d", code)
	}
	if !strings.Contains(out, "Token from:  MT_TOKEN (environment), over ") {
		t.Errorf("token source not clear:\n%s", out)
	}
	if !strings.Contains(out, "Project:     MT (") {
		t.Errorf("missing project:\n%s", out)
	}
}

func TestWhoamiInvalidToken(t *testing.T) {
	srv := whoamiServer(t)
	t.Setenv("MT_URL", "")
	t.Setenv("MT_TOKEN", "")
	_, errOut, code := runWhoamiIn(t, t.TempDir(), srv.URL, "bad")
	if code == 0 || !strings.Contains(errOut, "Error: the token from ") || !strings.Contains(errOut, "Hint: run mt setup") {
		t.Errorf("code %d, stderr:\n%s", code, errOut)
	}
}

func TestWhoamiNotConfigured(t *testing.T) {
	t.Setenv("MT_URL", "")
	t.Setenv("MT_TOKEN", "")
	_, errOut, code := runWhoamiIn(t, t.TempDir(), "", "")
	if code != 1 || !strings.Contains(errOut, "not configured") || !strings.Contains(errOut, "mt setup") {
		t.Errorf("code %d, stderr:\n%s", code, errOut)
	}
}

func TestWhoamiJSON(t *testing.T) {
	srv := whoamiServer(t)
	t.Setenv("MT_URL", srv.URL)
	t.Setenv("MT_TOKEN", "")
	out, _, code := runWhoamiIn(t, t.TempDir(), "", "good", "--json")
	if code != 0 {
		t.Fatalf("code %d", code)
	}
	var envl struct {
		OK   bool
		Data whoami
	}
	if err := json.Unmarshal([]byte(out), &envl); err != nil {
		t.Fatal(err)
	}
	d := envl.Data
	if !envl.OK || d.Actor.Name != "claude" || d.Actor.Kind != "agent" || d.URL != srv.URL || d.URLSource != SourceEnv || d.TokenSource != SourceFile || d.Project != nil {
		t.Errorf("unexpected envelope: %s", out)
	}

	out, _, code = runWhoamiIn(t, t.TempDir(), "", "bad", "--json")
	if code != 1 || !strings.Contains(out, `"code": "UNAUTHORIZED"`) {
		t.Errorf("code %d, out:\n%s", code, out)
	}
}

func TestWhoamiInHelp(t *testing.T) {
	var out bytes.Buffer
	printHelp(&out)
	setup := strings.SplitN(out.String(), "Set up\n", 2)[1]
	setup = strings.SplitN(setup, "\n\n", 2)[0]
	if !strings.Contains(setup, "whoami") {
		t.Errorf("whoami not in Set up:\n%s", setup)
	}
}
