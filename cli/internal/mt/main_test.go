package mt

import (
	"bytes"
	"os"
	"strings"
	"testing"
)

func TestFooterWriter(t *testing.T) {
	f, err := os.CreateTemp(t.TempDir(), "out")
	if err != nil {
		t.Fatal(err)
	}
	defer f.Close()
	var errBuf bytes.Buffer
	e := &env{stdout: f, stderr: &errBuf}
	if e.footerWriter() != &errBuf {
		t.Error("stdout en un fichero: el pie debe ir a stderr")
	}
	e.opts = parsed{flags: map[string][]string{"hook": {"true"}}}
	if e.footerWriter() != f {
		t.Error("con --hook el pie debe ir a stdout")
	}
}

// mt doc <slug> es el comando doc con un argumento; mt doc edit, su subcomando (MT-89).
func TestFindDocCommands(t *testing.T) {
	for argv, want := range map[string]string{"doc": "doc", "doc board": "doc", "doc edit board": "doc edit", "doc create board": "doc create", "doc delete board": "doc delete"} {
		if cmd := findCommand(strings.Fields(argv)); cmd == nil || cmd.name != want {
			t.Errorf("mt %s: want %q, got %v", argv, want, cmd)
		}
	}
}
