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
