package mt

import (
	"bytes"
	"os"
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
