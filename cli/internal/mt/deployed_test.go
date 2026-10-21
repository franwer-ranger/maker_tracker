package mt

import (
	"os/exec"
	"strings"
	"testing"
)

// gitIn corre git en dir y devuelve su salida sin el salto final.
func gitIn(t *testing.T, dir string, args ...string) string {
	t.Helper()
	cmd := exec.Command("git", append([]string{"-c", "user.name=t", "-c", "user.email=t@t", "-c", "commit.gpgsign=false"}, args...)...)
	cmd.Dir = dir
	out, err := cmd.CombinedOutput()
	if err != nil {
		t.Fatalf("git %v: %v\n%s", args, err, out)
	}
	return strings.TrimSpace(string(out))
}

func TestClassifyDeploy(t *testing.T) {
	dir := t.TempDir()
	gitIn(t, dir, "init", "-q", "-b", "main")
	gitIn(t, dir, "commit", "-q", "--allow-empty", "-m", "base")
	// Rama con un commit mergeada con merge commit (MT-30).
	gitIn(t, dir, "checkout", "-q", "-b", "feature")
	gitIn(t, dir, "commit", "-q", "--allow-empty", "-m", "MT-30: trabajo")
	merged := gitIn(t, dir, "rev-parse", "HEAD")
	gitIn(t, dir, "checkout", "-q", "main")
	gitIn(t, dir, "merge", "-q", "--no-ff", "feature", "-m", "Merge pull request #12 from acme/feature")
	// Un squash: el commit de la rama no existe en main, solo "(#13)".
	gitIn(t, dir, "commit", "-q", "--allow-empty", "-m", "MT-32: squash (#13)")
	deployed := gitIn(t, dir, "rev-parse", "HEAD")
	// Algo que existe pero no está en lo desplegado (MT-35).
	gitIn(t, dir, "checkout", "-q", "-b", "later")
	gitIn(t, dir, "commit", "-q", "--allow-empty", "-m", "MT-35: pendiente")
	later := gitIn(t, dir, "rev-parse", "HEAD")
	gitIn(t, dir, "checkout", "-q", "main")

	r := repo{dir: dir}
	missing := strings.Repeat("a", 40)
	candidates := []deployCandidate{
		{Reference: "MT-30", Number: 30, Commits: []string{merged[:7]}},
		{Reference: "MT-32", Number: 32, Commits: []string{missing}, PR: "https://github.com/acme/mt/pull/13"},
		{Reference: "MT-35", Number: 35, Commits: []string{later}},
		{Reference: "MT-31", Number: 31},
		{Reference: "MT-36", Number: 36, PR: "#99"},                            // PR sin rastro: espera
		{Reference: "MT-38", Number: 38, Commits: []string{"--output=/tmp/x"}}, // no es un sha: no existe, sin PR ni nada: se avisa
		{Reference: "MT-37", Number: 37, Commits: []string{merged, later}},     // uno no es ancestro: espera
	}
	ready, waiting, warnings := classifyDeploy(r, deployed, candidates)

	if got := references(ready); got != "MT-30, MT-32, MT-31, MT-38" {
		t.Errorf("ready = %s", got)
	}
	if got := references(waiting); got != "MT-35, MT-36, MT-37" {
		t.Errorf("waiting = %s", got)
	}
	if len(warnings) != 2 || !strings.Contains(warnings[0], "MT-31 has no commits or PR to check") || !strings.Contains(warnings[1], "MT-38 has no commits") {
		t.Errorf("warnings = %v", warnings)
	}
	want := "deployed " + deployed[:7] + ": MT-30, MT-32, MT-31, MT-38 can be tested now · MT-35, MT-36, MT-37 still waiting"
	if got := deployedLine(deployed, ready, waiting); got != want {
		t.Errorf("line = %q, want %q", got, want)
	}
}

func TestPRNumber(t *testing.T) {
	for in, want := range map[string]int{"https://github.com/a/b/pull/63": 63, "#7": 7, "12": 12, "": 0, "https://x.test/y": 0} {
		if got := prNumber(in); got != want {
			t.Errorf("prNumber(%q) = %d, want %d", in, got, want)
		}
	}
}

func TestResolveDeployedSha(t *testing.T) {
	dir := t.TempDir()
	gitIn(t, dir, "init", "-q", "-b", "main")
	gitIn(t, dir, "commit", "-q", "--allow-empty", "-m", "base")
	r := repo{dir: dir}
	head := gitIn(t, dir, "rev-parse", "HEAD")
	if sha, err := resolveDeployedSha(r, ""); err != nil || sha != head {
		t.Errorf("HEAD = %q, %v", sha, err)
	}
	if sha, err := resolveDeployedSha(r, head[:7]); err != nil || sha != head {
		t.Errorf("short sha = %q, %v", sha, err)
	}
	if _, err := resolveDeployedSha(r, strings.Repeat("b", 40)); err == nil {
		t.Error("un sha desconocido debe fallar")
	}
}
