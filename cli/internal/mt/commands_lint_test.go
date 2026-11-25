package mt

import (
	"bytes"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

// Sale con 1 si hay algún error (data.errors) y con 0 si solo hay avisos; --all va a /docs/lint.
func TestDocLintExitsWithErrors(t *testing.T) {
	var paths []string
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		paths = append(paths, r.URL.Path)
		if strings.Contains(r.URL.Path, "/board/") {
			w.Write([]byte(`{"ok":true,"data":{"errors":1,"warnings":0,"markdown":"board · Board: 1 error, 0 warnings\n"},"summary":"","breadcrumbs":[]}`))
			return
		}
		w.Write([]byte(`{"ok":true,"data":{"errors":0,"warnings":2,"markdown":"2 pages in MT: 1 with warnings and 1 read well.\n"},"summary":"","breadcrumbs":[]}`))
	}))
	defer srv.Close()
	t.Setenv("MT_URL", srv.URL)
	t.Setenv("MT_TOKEN", "mt_test")

	var out, errOut bytes.Buffer
	if code := Main([]string{"doc", "lint", "Board", "--project", "MT"}, nil, &out, &errOut); code != 1 {
		t.Errorf("with errors: exit %d, want 1", code)
	}
	if code := Main([]string{"doc", "lint", "--all", "--project", "MT"}, nil, &out, &errOut); code != 0 {
		t.Errorf("with warnings only: exit %d, want 0: %s", code, errOut.String())
	}
	if code := Main([]string{"doc", "lint", "--project", "MT"}, nil, &out, &errOut); code != 2 {
		t.Errorf("without a page: exit %d, want 2", code)
	}
	want := []string{"/api/projects/MT/docs/board/lint", "/api/projects/MT/docs/lint"}
	if strings.Join(paths, " ") != strings.Join(want, " ") {
		t.Errorf("paths %q, want %q", paths, want)
	}
	if !strings.Contains(out.String(), "board · Board: 1 error") {
		t.Errorf("it prints the markdown:\n%s", out.String())
	}
}

func TestDocHelpHasThePageFormat(t *testing.T) {
	var out bytes.Buffer
	printCommandHelp(&out, findCommand([]string{"doc"}))
	for _, want := range []string{"## Cómo funciona", "## ¿Qué pasa si…?", "mt doc lint"} {
		if !strings.Contains(out.String(), want) {
			t.Errorf("mt doc --help is missing %q", want)
		}
	}
}
