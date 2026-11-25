package mt

import (
	"bytes"
	"encoding/json"
	"io"
	"net/http"
	"net/http/httptest"
	"reflect"
	"strings"
	"testing"
)

// decisionsRequest ejecuta mt con args contra un servidor que guarda la
// petición que recibe (y su cuerpo) y responde ok.
func decisionsRequest(t *testing.T, args ...string) (*http.Request, string) {
	var got *http.Request
	var body []byte
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		got = r
		body, _ = io.ReadAll(r.Body)
		w.Header().Set("Content-Type", "application/json")
		w.Write([]byte(`{"ok":true,"data":{"markdown":"ok\n"}}`))
	}))
	t.Cleanup(srv.Close)
	t.Setenv("MT_URL", srv.URL)
	t.Setenv("MT_TOKEN", "good")
	var out, errOut bytes.Buffer
	if code := Main(append(args, "--project", "PG"), strings.NewReader(""), &out, &errOut); code != 0 {
		t.Fatalf("code %d: %s", code, errOut.String())
	}
	return got, string(body)
}

// mt decide --capability, una o varias (MT-90).
func TestDecideSendsCapabilities(t *testing.T) {
	_, raw := decisionsRequest(t, "decide", "Plantillas en JSON", "--why", "sin tabla", "--capability", "editor", "--capability", "calendario")
	var body map[string]any
	if err := json.Unmarshal([]byte(raw), &body); err != nil {
		t.Fatal(err)
	}
	if want := []any{"editor", "calendario"}; !reflect.DeepEqual(body["capabilities"], want) {
		t.Errorf("capabilities = %v, want %v", body["capabilities"], want)
	}

	if _, raw = decisionsRequest(t, "decide", "Sin capacidad", "--why", "x"); strings.Contains(raw, "capabilities") {
		t.Errorf("no capabilities expected: %s", raw)
	}
}

// mt decisions --capability filtra en el servidor (MT-90).
func TestDecisionsFiltersByCapability(t *testing.T) {
	r, _ := decisionsRequest(t, "decisions", "--capability", "editor")
	if r.URL.Path != "/api/projects/PG/decisions" || r.URL.Query().Get("capability") != "editor" {
		t.Errorf("request = %s", r.URL)
	}
	if r, _ = decisionsRequest(t, "decisions"); r.URL.RawQuery != "" {
		t.Errorf("no query expected: %s", r.URL)
	}
}

// mt decision link/unlink: varias decisiones y capacidades al endpoint (MT-115).
func TestDecisionLinkSendsDecisionsAndCapabilities(t *testing.T) {
	for _, action := range []string{"link", "unlink"} {
		r, raw := decisionsRequest(t, "decision", action, "D-45", "D-52", "--capability", "revelarlo", "--capability", "ir-a-buscarlo")
		if r.Method != "POST" || r.URL.Path != "/api/projects/PG/decisions/"+action {
			t.Errorf("%s request = %s %s", action, r.Method, r.URL)
		}
		var body map[string]any
		if err := json.Unmarshal([]byte(raw), &body); err != nil {
			t.Fatal(err)
		}
		if want := []any{"D-45", "D-52"}; !reflect.DeepEqual(body["decisions"], want) {
			t.Errorf("%s decisions = %v, want %v", action, body["decisions"], want)
		}
		if want := []any{"revelarlo", "ir-a-buscarlo"}; !reflect.DeepEqual(body["capabilities"], want) {
			t.Errorf("%s capabilities = %v, want %v", action, body["capabilities"], want)
		}
	}
}

// Sin --capability o sin decisión es un error de uso, sin llamar a la API.
func TestDecisionLinkNeedsDecisionAndCapability(t *testing.T) {
	t.Setenv("MT_URL", "http://127.0.0.1:1")
	t.Setenv("MT_TOKEN", "good")
	for _, args := range [][]string{{"decision", "link", "D-52"}, {"decision", "unlink", "--capability", "revelarlo"}} {
		var out, errOut bytes.Buffer
		if code := Main(append(args, "--project", "PG"), strings.NewReader(""), &out, &errOut); code != 2 {
			t.Errorf("%v: code %d, want 2 (%s)", args, code, errOut.String())
		}
	}
}
