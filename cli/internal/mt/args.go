package mt

import (
	"fmt"
	"strings"
)

// UsageError es un error de uso: mt sale con código 2.
type UsageError struct{ msg, hint string }

func (e *UsageError) Error() string { return e.msg }

func usageErrorf(format string, args ...any) error {
	return &UsageError{msg: fmt.Sprintf(format, args...)}
}

// usageHint: un error de uso con su Hint.
func usageHint(hint, format string, args ...any) error {
	return &UsageError{msg: fmt.Sprintf(format, args...), hint: hint}
}

// hintedError: un error que no es de uso (código 1) con su Hint.
type hintedError struct{ msg, hint string }

func (e *hintedError) Error() string { return e.msg }

type flagKind int

const (
	boolFlag flagKind = iota
	stringFlag
	multiFlag // se puede repetir: --commit a --commit b
)

// Flags que admiten todos los comandos.
var globalFlags = map[string]flagKind{"json": boolFlag, "project": stringFlag, "help": boolFlag}

type parsed struct {
	args  []string
	flags map[string][]string
}

func (p parsed) has(name string) bool { _, ok := p.flags[name]; return ok }

func (p parsed) get(name string) string {
	if v := p.flags[name]; len(v) > 0 {
		return v[len(v)-1]
	}
	return ""
}

func (p parsed) all(name string) []string { return p.flags[name] }

// parseArgs separa argumentos y flags, en cualquier orden (mt done PG-49
// --commit abc). Admite --flag valor y --flag=valor; "--" corta.
func parseArgs(args []string, known map[string]flagKind) (parsed, error) {
	p := parsed{flags: map[string][]string{}}
	for i := 0; i < len(args); i++ {
		arg := args[i]
		if arg == "--" {
			p.args = append(p.args, args[i+1:]...)
			break
		}
		if arg == "-h" {
			arg = "--help"
		}
		if !strings.HasPrefix(arg, "--") || arg == "--" {
			p.args = append(p.args, arg)
			continue
		}
		name, value, hasValue := strings.Cut(strings.TrimPrefix(arg, "--"), "=")
		kind, ok := known[name]
		if !ok {
			kind, ok = globalFlags[name]
		}
		if !ok {
			return p, usageHint("see the options with mt <command> --help.", "unknown option --%s.", name)
		}
		if kind == boolFlag {
			if hasValue {
				return p, usageErrorf("--%s takes no value.", name)
			}
			p.flags[name] = append(p.flags[name], "true")
			continue
		}
		if !hasValue {
			if i+1 >= len(args) {
				return p, usageErrorf("--%s needs a value.", name)
			}
			i++
			value = args[i]
		}
		p.flags[name] = append(p.flags[name], value)
	}
	return p, nil
}
