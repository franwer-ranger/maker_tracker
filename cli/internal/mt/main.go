// Package mt implementa el CLI de Maker Tracker. Cada comando es una llamada a
// la API (/api) de la instancia configurada con mt setup.
package mt

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"os"
	"sort"
	"strings"
)

// Version del binario. Se puede fijar al compilar con -ldflags "-X …Version=…".
var Version = "0.1.0"

// env es lo que necesita un comando para ejecutarse.
type env struct {
	stdin          io.Reader
	stdout, stderr io.Writer
	opts           parsed
	cfg            Config
	client         *Client
}

func (e *env) arg(i int) string {
	if i < len(e.opts.args) {
		return e.opts.args[i]
	}
	return ""
}

// Main ejecuta mt y devuelve el código de salida: 0 bien, 1 error, 2 error de uso.
func Main(argv []string, stdin io.Reader, stdout, stderr io.Writer) int {
	argv = moveLeadingGlobals(argv)
	if len(argv) == 0 || argv[0] == "help" || argv[0] == "--help" || argv[0] == "-h" {
		if len(argv) > 1 {
			if cmd := findCommand(argv[1:]); cmd != nil {
				printCommandHelp(stdout, cmd)
				return 0
			}
			fmt.Fprintf(stderr, "No existe el comando %q. Mira mt help\n", strings.Join(argv[1:], " "))
			return 2
		}
		printHelp(stdout)
		return 0
	}
	if argv[0] == "version" || argv[0] == "--version" {
		fmt.Fprintf(stdout, "mt %s (API v%s)\n", Version, APIVersion)
		return 0
	}

	cmd := findCommand(argv)
	if cmd == nil && argv[0] == "milestone" {
		fmt.Fprintln(stderr, "Uso: mt milestone create | edit | reorder | close | reopen …. Mira mt help")
		return 2
	}
	if cmd == nil {
		fmt.Fprintf(stderr, "No existe el comando %q. Mira mt help\n", argv[0])
		return 2
	}
	opts, err := parseArgs(argv[len(strings.Fields(cmd.name)):], cmd.flags)
	if err == nil && opts.has("help") {
		printCommandHelp(stdout, cmd)
		return 0
	}
	if err == nil && (len(opts.args) < cmd.minArgs || (cmd.maxArgs >= 0 && len(opts.args) > cmd.maxArgs)) {
		err = usageErrorf("uso: %s", cmd.usage)
	}
	if err != nil {
		return fail(stderr, err)
	}

	cfg, err := loadConfig()
	if err != nil {
		return fail(stderr, err)
	}
	e := &env{stdin: stdin, stdout: stdout, stderr: stderr, opts: opts, cfg: cfg, client: newClient(cfg)}
	code := 0
	if err := cmd.run(e); err != nil {
		code = fail(stderr, err)
	}
	if e.client.VersionWarning != "" {
		fmt.Fprintln(stderr, "Aviso: "+e.client.VersionWarning)
	}
	return code
}

// moveLeadingGlobals pasa las flags globales de delante del comando al final:
// mt --project PG next → mt next --project PG.
func moveLeadingGlobals(argv []string) []string {
	var globals []string
	for len(argv) > 0 && strings.HasPrefix(argv[0], "--") {
		name, _, hasValue := strings.Cut(strings.TrimPrefix(argv[0], "--"), "=")
		kind, ok := globalFlags[name]
		if !ok || name == "help" {
			break
		}
		n := 1
		if kind != boolFlag && !hasValue {
			n = 2
		}
		n = min(n, len(argv))
		globals, argv = append(globals, argv[:n]...), argv[n:]
	}
	return append(argv, globals...)
}

func fail(stderr io.Writer, err error) int {
	if _, ok := err.(silentError); ok {
		return 1
	}
	if apiErr, ok := err.(*APIError); ok {
		fmt.Fprintf(stderr, "Error (%s): %s\n", apiErr.Code, apiErr.Message)
		if apiErr.Hint != "" {
			fmt.Fprintf(stderr, "%s\n", apiErr.Hint)
		}
		return 1
	}
	fmt.Fprintf(stderr, "Error: %s\n", err)
	if isUsage(err) {
		return 2
	}
	return 1
}

// call hace la llamada y pinta la respuesta.
func (e *env) call(method, path string, query map[string]string, body any) error {
	values := map[string][]string{}
	for k, v := range query {
		if v != "" {
			values[k] = []string{v}
		}
	}
	envl, err := e.client.Do(method, path, values, body)
	if err != nil {
		return err
	}
	return e.render(envl)
}

// render: con --json, el sobre tal cual. Si no, el markdown (o el summary),
// los avisos y "Siguiente:" con los breadcrumbs. Igual con o sin TTY.
func (e *env) render(envl *Envelope) error {
	if e.opts.has("json") {
		var pretty bytes.Buffer
		if json.Indent(&pretty, envl.raw, "", "  ") != nil {
			pretty.Reset()
			pretty.Write(envl.raw)
		}
		fmt.Fprintln(e.stdout, pretty.String())
		if !envl.OK {
			return silentError{}
		}
		return nil
	}
	if !envl.OK {
		return envl.Error
	}

	text := envl.Markdown()
	if text == "" {
		text = envl.Summary
	}
	fmt.Fprintln(e.stdout, strings.TrimRight(text, "\n"))
	if len(envl.Warnings) > 0 {
		fmt.Fprintln(e.stdout, "\nAvisos:")
		for _, w := range envl.Warnings {
			fmt.Fprintf(e.stdout, "- %s\n", w)
		}
	}
	if len(envl.Breadcrumbs) > 0 {
		fmt.Fprintln(e.stdout, "\nSiguiente:")
		for _, b := range envl.Breadcrumbs {
			fmt.Fprintf(e.stdout, "  %s\n", b)
		}
	}
	return nil
}

// silentError: el error ya se ha impreso (en --json), solo cambia el código de salida.
type silentError struct{}

func (silentError) Error() string { return "" }

func printHelp(w io.Writer) {
	fmt.Fprintf(w, "mt %s · Maker Tracker desde la terminal\n\nUso: mt <comando> [argumentos] [--json] [--project PG]\n\n", Version)
	groups := map[string][]*command{}
	var order []string
	for _, cmd := range commands {
		if _, ok := groups[cmd.group]; !ok {
			order = append(order, cmd.group)
		}
		groups[cmd.group] = append(groups[cmd.group], cmd)
	}
	for _, group := range order {
		fmt.Fprintf(w, "%s\n", group)
		cmds := groups[group]
		width := 0
		for _, c := range cmds {
			width = max(width, len(c.name))
		}
		for _, c := range cmds {
			fmt.Fprintf(w, "  %-*s  %s\n", width, c.name, c.summary)
		}
		fmt.Fprintln(w)
	}
	fmt.Fprint(w, `Historias: PG-49 o solo 49 (con el proyecto de .mt o --project).
--file - lee de la entrada estándar. --json imprime el sobre de la API tal cual.
Más detalle: mt <comando> --help
`)
}

func printCommandHelp(w io.Writer, cmd *command) {
	fmt.Fprintf(w, "Uso: %s\n\n%s\n", cmd.usage, cmd.summary)
	if cmd.description != "" {
		fmt.Fprintf(w, "\n%s\n", cmd.description)
	}
	if len(cmd.flags) > 0 {
		names := make([]string, 0, len(cmd.flags))
		for name := range cmd.flags {
			names = append(names, name)
		}
		sort.Strings(names)
		fmt.Fprintln(w, "\nOpciones:")
		for _, name := range names {
			fmt.Fprintf(w, "  --%s %s\n", name, cmd.flagHelp[name])
		}
	}
	fmt.Fprintf(w, "\nEjemplo:\n  %s\n", cmd.example)
}

func readFileArg(e *env, path string) (string, error) {
	if path == "-" {
		data, err := io.ReadAll(e.stdin)
		return string(data), err
	}
	data, err := os.ReadFile(path)
	if err != nil {
		return "", usageErrorf("no se puede leer %s: %v", path, err)
	}
	return string(data), nil
}
