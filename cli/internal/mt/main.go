// Package mt implementa el CLI de Maker Tracker. Cada comando es una llamada a
// la API (/api) de la instancia configurada con mt setup.
package mt

import (
	"bytes"
	"encoding/json"
	"errors"
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
			return fail(stderr, unknownCommand(strings.Join(argv[1:], " ")))
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
		return fail(stderr, &UsageError{msg: "mt milestone needs a subcommand.", hint: "mt milestone create | edit | reorder | close | reopen. See mt help."})
	}
	if cmd == nil && (argv[0] == "project" || argv[0] == "skill") {
		return fail(stderr, &UsageError{msg: "mt " + argv[0] + " needs a subcommand.", hint: map[string]string{"project": "mt project create \"Name\" --key PG", "skill": "mt skill install"}[argv[0]]})
	}
	if cmd == nil {
		return fail(stderr, unknownCommand(argv[0]))
	}
	opts, err := parseArgs(argv[len(strings.Fields(cmd.name)):], cmd.flags)
	if err == nil && opts.has("help") {
		printCommandHelp(stdout, cmd)
		return 0
	}
	if err == nil && (len(opts.args) < cmd.minArgs || (cmd.maxArgs >= 0 && len(opts.args) > cmd.maxArgs)) {
		err = &UsageError{msg: "wrong number of arguments.", hint: "usage: " + cmd.usage}
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
	if e.client.VersionWarning != "" && !e.opts.has("hook") {
		fmt.Fprintln(stderr, "Warning: "+e.client.VersionWarning)
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

func unknownCommand(name string) error {
	return &UsageError{msg: fmt.Sprintf("unknown command %q.", name), hint: "see the commands with mt help."}
}

// fail imprime el error en dos líneas por stderr (Error: … / Hint: …) y
// devuelve el código de salida: 2 si el comando está mal escrito, 1 si no.
func fail(stderr io.Writer, err error) int {
	if _, ok := err.(silentError); ok {
		return 1
	}
	message, hint, code := err.Error(), "", 1
	var usage *UsageError
	switch e := err.(type) {
	case *APIError:
		hint = e.Hint
	case *hintedError:
		hint = e.hint
	default:
		if errors.As(err, &usage) {
			hint, code = usage.hint, 2
		}
	}
	fmt.Fprintf(stderr, "Error: %s\n", message)
	if hint != "" {
		fmt.Fprintf(stderr, "Hint: %s\n", hint)
	}
	return code
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
// los avisos (Warning: …) y "Next:" con los breadcrumbs (docs/CLI.md). El pie
// va a stdout en una terminal y a stderr si stdout se redirige (footerWriter).
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
	printFooter(e.footerWriter(), envl.Warnings, envl.Breadcrumbs)
	return nil
}

// footerWriter: dónde va el pie. En una terminal, stdout (se ve como siempre).
// Si stdout es un fichero o una tubería (mt brief > f.md), el pie va a stderr
// para que no se cuele en el fichero que luego se vuelve a subir. Con --hook
// (SessionStart) siempre a stdout: Claude Code solo inyecta el stdout del hook.
func (e *env) footerWriter() io.Writer {
	if e.opts.has("hook") {
		return e.stdout
	}
	if f, ok := e.stdout.(*os.File); ok {
		if info, err := f.Stat(); err == nil && info.Mode()&os.ModeCharDevice == 0 {
			return e.stderr
		}
	}
	return e.stdout
}

// printFooter: los avisos, uno por línea, y después Next: con los comandos.
func printFooter(w io.Writer, warnings, next []string) {
	for _, warning := range warnings {
		fmt.Fprintf(w, "Warning: %s\n", warning)
	}
	if len(next) > 0 {
		fmt.Fprintln(w, "\nNext:")
		for _, b := range next {
			fmt.Fprintf(w, "  %s\n", b)
		}
	}
}

// silentError: el error ya se ha impreso (en --json), solo cambia el código de salida.
type silentError struct{}

func (silentError) Error() string { return "" }

func printHelp(w io.Writer) {
	fmt.Fprintf(w, "mt %s · Maker Tracker from the terminal\n\nUsage: mt <command> [arguments] [--json] [--project PG]\n\n", Version)
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
	fmt.Fprint(w, `Stories: PG-49, or just 49 (with the project from .mt or --project).
--file - reads from standard input. --json prints the API envelope as is.
More: mt <command> --help
`)
}

func printCommandHelp(w io.Writer, cmd *command) {
	fmt.Fprintf(w, "Usage: %s\n\n%s\n", cmd.usage, cmd.summary)
	if cmd.description != "" {
		fmt.Fprintf(w, "\n%s\n", cmd.description)
	}
	if len(cmd.flags) > 0 {
		names := make([]string, 0, len(cmd.flags))
		for name := range cmd.flags {
			names = append(names, name)
		}
		sort.Strings(names)
		fmt.Fprintln(w, "\nOptions:")
		for _, name := range names {
			fmt.Fprintf(w, "  --%s %s\n", name, cmd.flagHelp[name])
		}
	}
	fmt.Fprintf(w, "\nExample:\n  %s\n", cmd.example)
}

func readFileArg(e *env, path string) (string, error) {
	if path == "-" {
		data, err := io.ReadAll(e.stdin)
		return string(data), err
	}
	data, err := os.ReadFile(path)
	if err != nil {
		return "", usageErrorf("can't read %s: %v.", path, err)
	}
	return string(data), nil
}
