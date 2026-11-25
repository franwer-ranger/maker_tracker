package mt

import (
	"errors"
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
