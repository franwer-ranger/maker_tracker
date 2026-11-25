package mt

import (
	"errors"
	"mime"
	"mime/multipart"
	"os"
	"path/filepath"
	"testing"
)

func TestHumanSizeLikeTheAPI(t *testing.T) {
	cases := map[int64]string{28: "28 Bytes", 120_000: "117 KB", 3_410: "3.33 KB", 100 << 20: "100 MB", 3 << 30: "3 GB"}
	for bytes, want := range cases {
		if got := humanSize(bytes); got != want {
			t.Errorf("humanSize(%d) = %q, want %q", bytes, got, want)
		}
	}
}

func TestMultipartBodyRejectsFilesOverTheLimitWithoutReadingThem(t *testing.T) {
	path := filepath.Join(t.TempDir(), "video.mp4")
	file, err := os.Create(path)
	if err != nil {
		t.Fatal(err)
	}
	if err := file.Truncate(120 << 20); err != nil { // disperso: no ocupa disco
		t.Fatal(err)
	}
	file.Close()

	_, _, err = multipartBody(Upload{Path: path})
	var usage *UsageError
	if !errors.As(err, &usage) {
		t.Fatalf("want a UsageError, got %v", err)
	}
	if want := "video.mp4 is 120 MB: the limit is 100 MB."; usage.msg != want {
		t.Errorf("msg = %q, want %q", usage.msg, want)
	}
}

func TestMultipartBodySendsTheFieldsWithTheFile(t *testing.T) {
	path := filepath.Join(t.TempDir(), "captura.png")
	if err := os.WriteFile(path, []byte("png"), 0o600); err != nil {
		t.Fatal(err)
	}

	body, contentType, err := multipartBody(Upload{Path: path, Fields: map[string]string{"alt": "El tablero, vacío"}})
	if err != nil {
		t.Fatal(err)
	}
	_, params, err := mime.ParseMediaType(contentType)
	if err != nil {
		t.Fatal(err)
	}
	form, err := multipart.NewReader(body, params["boundary"]).ReadForm(1 << 20)
	if err != nil {
		t.Fatal(err)
	}
	if got := form.Value["alt"]; len(got) != 1 || got[0] != "El tablero, vacío" {
		t.Errorf("alt = %q, want the caption", got)
	}
	if files := form.File["file"]; len(files) != 1 || files[0].Filename != "captura.png" {
		t.Errorf("file = %v, want captura.png", files)
	}
}
