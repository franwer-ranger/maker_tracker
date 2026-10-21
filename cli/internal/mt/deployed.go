package mt

import (
	"fmt"
	"os/exec"
	"regexp"
	"strconv"
	"strings"
)

// mt deployed [<sha>] (MT-46, D-62..D-64): avisa de que un sha está desplegado
// para que las historias Hechas que contiene salgan en «Por probar». El CLI
// decide con git qué contiene el sha y se lo dice a la API; el servidor no
// necesita el repo.

// deployCandidate es una historia Hecha con QA pendiente y sin desplegar, tal
// como la devuelve GET /api/projects/:key/deployed.
type deployCandidate struct {
	Reference string   `json:"reference"`
	Number    int      `json:"number"`
	Commits   []string `json:"commits"`
	PR        string   `json:"pr"`
}

// repo es el repositorio git donde corre mt (el directorio actual).
type repo struct{ dir string }

func (r repo) git(args ...string) *exec.Cmd {
	cmd := exec.Command("git", args...)
	cmd.Dir = r.dir
	return cmd
}

// resolve devuelve el sha completo de ref, o error si no es un commit conocido.
func (r repo) resolve(ref string) (string, error) {
	out, err := r.git("rev-parse", "--verify", "--quiet", "--end-of-options", ref+"^{commit}").Output()
	if err != nil {
		return "", err
	}
	return strings.TrimSpace(string(out)), nil
}

// commitPattern: lo único que se acepta como commit venido del servidor. Algo
// que no lo cumple se trata como «no existe aquí» y nunca llega a git.
var commitPattern = regexp.MustCompile(`^[0-9a-f]{7,40}$`)

func (r repo) exists(sha string) bool {
	if !commitPattern.MatchString(sha) {
		return false
	}
	_, err := r.resolve(sha)
	return err == nil
}

// isAncestor: `git merge-base --is-ancestor` (sale con 0 si lo es).
func (r repo) isAncestor(sha, of string) bool {
	return r.git("merge-base", "--is-ancestor", "--end-of-options", sha, of).Run() == nil
}

// subjects son los asuntos del historial de sha, para buscar PR (#N).
func (r repo) subjects(sha string) []string {
	out, err := r.git("log", "--format=%s", "--end-of-options", sha).Output()
	if err != nil {
		return nil
	}
	return strings.Split(string(out), "\n")
}

var prNumberPattern = regexp.MustCompile(`(?:/pull/|#)?(\d+)/?$`)

// prNumber saca el número de la URL de un PR (…/pull/63) o de "#63".
func prNumber(pr string) int {
	m := prNumberPattern.FindStringSubmatch(strings.TrimSpace(pr))
	if m == nil {
		return 0
	}
	n, _ := strconv.Atoi(m[1])
	return n
}

// prInHistory: algún asunto es «Merge pull request #N …» o termina en «(#N)».
func prInHistory(subjects []string, n int) bool {
	pattern := regexp.MustCompile(fmt.Sprintf(`^Merge pull request #%d\b|\(#%d\)`, n, n))
	for _, subject := range subjects {
		if pattern.MatchString(subject) {
			return true
		}
	}
	return false
}

// classifyDeploy decide qué historias contiene sha, en este orden (D-63):
//  1. Tiene commits que existen aquí: todos tienen que ser ancestros de sha.
//  2. Ninguno existe aquí (un squash) pero tiene PR: el historial de sha contiene su #N.
//  3. Sin commits ni PR que comprobar: se da por desplegada en esta llamada y se avisa.
//
// Una con un commit que existe y no es ancestro sigue esperando, sin error. Una
// con PR y sin rastro (ningún commit aquí y el PR no está en el historial) también
// espera: es la opción conservadora (D-68, que sustituye a D-63 en este punto), mejor esperar que enseñar
// como probable algo que aún no está desplegado.
func classifyDeploy(r repo, sha string, candidates []deployCandidate) (ready, waiting []deployCandidate, warnings []string) {
	var subjects []string
	loaded := false
	for _, c := range candidates {
		var known []string
		for _, commit := range c.Commits {
			if r.exists(commit) {
				known = append(known, commit)
			}
		}
		if len(known) > 0 {
			contained := true
			for _, commit := range known {
				contained = contained && r.isAncestor(commit, sha)
			}
			if contained {
				ready = append(ready, c)
			} else {
				waiting = append(waiting, c)
			}
			continue
		}

		if n := prNumber(c.PR); n > 0 {
			if !loaded {
				subjects, loaded = r.subjects(sha), true
			}
			if prInHistory(subjects, n) {
				ready = append(ready, c)
				continue
			}
			waiting = append(waiting, c)
			continue
		}
		warnings = append(warnings, fmt.Sprintf("%s has no commits or PR to check: I take it as deployed.", c.Reference))
		ready = append(ready, c)
	}
	return ready, waiting, warnings
}

func short(sha string) string {
	if len(sha) > 7 {
		return sha[:7]
	}
	return sha
}

func references(list []deployCandidate) string {
	refs := make([]string, len(list))
	for i, c := range list {
		refs[i] = c.Reference
	}
	return strings.Join(refs, ", ")
}

// deployedLine: "deployed a1b2c3d: MT-30, MT-32 can be tested now · MT-35 still waiting".
func deployedLine(sha string, ready, waiting []deployCandidate) string {
	parts := []string{}
	if len(ready) > 0 {
		parts = append(parts, references(ready)+" can be tested now")
	}
	if len(waiting) > 0 {
		parts = append(parts, references(waiting)+" still waiting")
	}
	if len(parts) == 0 {
		parts = append(parts, "no story was waiting for a deploy")
	}
	return fmt.Sprintf("deployed %s: %s", short(sha), strings.Join(parts, " · "))
}

func runDeployed(e *env) error {
	path, err := e.projectPath()
	if err != nil {
		return err
	}
	r := repo{}
	sha, err := resolveDeployedSha(r, e.arg(0))
	if err != nil {
		return err
	}

	list, err := e.client.Do("GET", path+"/deployed", nil, nil)
	if err != nil {
		return err
	}
	if !list.OK {
		return list.Error
	}
	var data struct {
		Stories []deployCandidate `json:"stories"`
	}
	if err := jsonUnmarshal(list.Data, &data); err != nil {
		return err
	}

	ready, waiting, warnings := classifyDeploy(r, sha, data.Stories)
	numbers := make([]int, len(ready))
	for i, c := range ready {
		numbers[i] = c.Number
	}
	// Siempre se envía, aunque no haya nada que marcar: la primera llamada activa la espera en el proyecto.
	// Los avisos también van en el evento, para que quede por qué se dio una por desplegada.
	posted, err := e.client.Do("POST", path+"/deployed", nil, map[string]any{"sha": sha, "stories": numbers, "warnings": warnings})
	if err != nil {
		return err
	}
	if e.opts.has("json") {
		return e.render(posted)
	}
	if !posted.OK {
		return posted.Error
	}
	fmt.Fprintln(e.stdout, deployedLine(sha, ready, waiting))
	next := []string{"mt qa"}
	if len(waiting) > 0 {
		next = append(next, "mt deployed   (again, when "+references(waiting)+" is deployed)")
	}
	printFooter(e.footerWriter(), warnings, next)
	return nil
}

// resolveDeployedSha: el sha pedido o HEAD. Si no existe en local, un
// `git fetch` best-effort antes de rendirse.
func resolveDeployedSha(r repo, ref string) (string, error) {
	if ref == "" {
		sha, err := r.resolve("HEAD")
		if err != nil {
			return "", usageHint("run it at the root of the repo that was deployed, or pass the sha: mt deployed a1b2c3d.", "there is no git commit here to say what is deployed.")
		}
		return sha, nil
	}
	if sha, err := r.resolve(ref); err == nil {
		return sha, nil
	}
	_ = r.git("fetch", "--quiet").Run()
	if sha, err := r.resolve(ref); err == nil {
		return sha, nil
	}
	return "", usageHint("check the sha, or git fetch by hand if it is on a branch you don't have.", "%s is not a commit of this repo, not even after git fetch.", ref)
}

func init() {
	def(&command{name: "deployed", group: "Work on a story", usage: "mt deployed [<sha>] [--project PG]", maxArgs: 1,
		summary:     "Tells Maker Tracker that a sha is deployed: the stories done in it can be tested now",
		description: "Run it at the root of the repo, at the end of the deploy script (bin/deploy does). sha defaults to HEAD. It marks the stories done and waiting for QA whose commits are ancestors of the sha (or, after a squash, whose PR is in its history). The first call turns on the wait for deploys in the project: from then on \"Por probar\" and mt qa only list what was deployed. Calling again with the same or a later sha is safe. Any actor can run it.",
		example:     "mt deployed a1b2c3d", run: runDeployed})
}
