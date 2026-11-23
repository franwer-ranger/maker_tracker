package mt

import (
	"bytes"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

func TestCheckGoesAfterDecisionsInHelp(t *testing.T) {
	var out bytes.Buffer
	printHelp(&out)
	help := out.String()
	decisions, check := strings.Index(help, "  decisions "), strings.Index(help, "  check ")
	if decisions < 0 || check < decisions || strings.Index(help, "Set up") > decisions {
		t.Errorf("mt check debe salir en Read, detrás de decisions:\n%s", help)
	}
}

// Con texto va por GET (?text=…); con --file, por POST con el texto en el cuerpo.
func TestCheckSendsTheProposal(t *testing.T) {
	var got []string
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		body := new(bytes.Buffer)
		body.ReadFrom(r.Body)
		got = append(got, r.Method+" "+r.URL.Path+" "+r.URL.Query().Get("text")+strings.TrimSpace(body.String()))
		w.Write([]byte(`{"ok":true,"data":{"markdown":"# Check\n"},"summary":"","breadcrumbs":[]}`))
	}))
	defer srv.Close()
	t.Setenv("MT_URL", srv.URL)
	t.Setenv("MT_TOKEN", "mt_test")

	var out, errOut bytes.Buffer
	if code := Main([]string{"check", "avisar de casi listas", "--project", "MT"}, nil, &out, &errOut); code != 0 {
		t.Fatalf("exit %d: %s", code, errOut.String())
	}
	if code := Main([]string{"check", "--file", "-", "--project", "MT"}, strings.NewReader("una propuesta larga"), &out, &errOut); code != 0 {
		t.Fatalf("exit %d: %s", code, errOut.String())
	}
	want := []string{"GET /api/projects/MT/check avisar de casi listas", `POST /api/projects/MT/check {"text":"una propuesta larga"}`}
	if strings.Join(got, "\n") != strings.Join(want, "\n") {
		t.Errorf("got %q, want %q", got, want)
	}
}
