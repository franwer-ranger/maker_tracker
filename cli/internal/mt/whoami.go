package mt

import (
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strings"
)

// whoami es lo que imprime mt whoami: con qué actor firmas, en qué instancia y
// de dónde salen la URL y el token (MT-83). Con --json va en data del sobre.
type whoami struct {
	Actor       *whoamiActor   `json:"actor,omitempty"`
	URL         string         `json:"url"`
	URLSource   string         `json:"url_source"`   // env (MT_URL), file o ""
	TokenSource string         `json:"token_source"` // env (MT_TOKEN), file o ""
	ConfigPath  string         `json:"config_path"`
	Project     *whoamiProject `json:"project"`
}

type whoamiActor struct {
	Name string `json:"name"`
	Kind string `json:"kind,omitempty"` // human o agent; vacío si la instancia no lo dice
}

type whoamiProject struct {
	Key  string `json:"key"`
	File string `json:"file"`
}

// mt whoami: GET /api/projects (la misma llamada que el «Connected as» de mt
// setup) y, con la respuesta, quién eres, dónde y de dónde sale cada cosa.
func runWhoami(e *env) error {
	info := whoami{URL: e.cfg.URL, URLSource: e.cfg.URLFrom, TokenSource: e.cfg.TokenFrom, ConfigPath: e.cfg.Path}
	var warnings []string
	if dir, err := os.Getwd(); err == nil {
		key, file, err := findProject(dir)
		switch {
		case err != nil:
			warnings = append(warnings, oneLine(err))
		case key != "":
			info.Project = &whoamiProject{Key: key, File: file}
		}
	}

	if err := e.whoamiActor(&info); err != nil {
		if e.opts.has("json") {
			return whoamiEnvelope{OK: false, Data: info, Warnings: warnings, Error: whoamiError(err)}.print(e.stdout)
		}
		printFooter(e.stderr, warnings, nil)
		return err
	}

	summary := info.Actor.Name
	if info.Actor.Kind != "" {
		summary += " (" + info.Actor.Kind + ")"
	}
	summary += " at " + info.URL
	next := []string{"mt projects"}
	if info.Project != nil {
		next = []string{"mt context"}
	}
	if e.opts.has("json") {
		return whoamiEnvelope{OK: true, Data: info, Summary: summary + ".", Breadcrumbs: next, Warnings: warnings}.print(e.stdout)
	}

	fmt.Fprintf(e.stdout, "%s\n\n", summary)
	fmt.Fprintf(e.stdout, "URL from:    %s\n", e.cfg.describeSource("MT_URL", e.cfg.URLFrom, e.cfg.FileHasURL))
	fmt.Fprintf(e.stdout, "Token from:  %s\n", e.cfg.describeSource("MT_TOKEN", e.cfg.TokenFrom, e.cfg.FileHasToken))
	if info.Project != nil {
		fmt.Fprintf(e.stdout, "Project:     %s (%s)\n", info.Project.Key, displayPath(info.Project.File))
	}
	printFooter(e.footerWriter(), warnings, next)
	return nil
}

// whoamiActor pregunta a la instancia por el actor del token. Los errores
// dicen de dónde sale lo que falla y sugieren mt setup.
func (e *env) whoamiActor(info *whoami) error {
	const setupHint = "run mt setup <url> <token>. Create the token on the server with bin/rails \"mt:token[your-name]\" only if you don't have one yet."
	file := displayPath(e.cfg.Path)
	switch {
	case e.cfg.URL == "":
		return &APIError{Code: "NOT_CONFIGURED", Message: fmt.Sprintf("mt is not configured: no url in %s and no MT_URL.", file), Hint: setupHint}
	case e.cfg.Token == "":
		return &APIError{Code: "NOT_CONFIGURED", Message: fmt.Sprintf("mt has no token: none in %s and no MT_TOKEN.", file), Hint: setupHint}
	}

	envl, err := e.client.Do("GET", "/api/projects", nil, nil)
	if err != nil {
		return err
	}
	if !envl.OK {
		if envl.Error.Code == "UNAUTHORIZED" {
			hint := setupHint
			if e.cfg.TokenFrom == SourceEnv {
				hint = "MT_TOKEN takes precedence over " + file + ": fix or unset it, or " + setupHint
			}
			return &APIError{Code: "UNAUTHORIZED", Message: fmt.Sprintf("the token from %s is not valid on %s.", e.cfg.describeSource("MT_TOKEN", e.cfg.TokenFrom, false), e.cfg.URL), Hint: hint}
		}
		return envl.Error
	}
	var data struct {
		Actor     string `json:"actor"`
		ActorKind string `json:"actor_kind"`
	}
	if err := jsonUnmarshal(envl.Data, &data); err != nil || data.Actor == "" {
		return &APIError{Code: "UNEXPECTED_RESPONSE", Message: e.cfg.URL + " did not say which actor the token belongs to.", Hint: "update the instance, or check the url with mt setup <url> <token>."}
	}
	info.Actor = &whoamiActor{Name: data.Actor, Kind: data.ActorKind}
	return nil
}

// describeSource: «MT_TOKEN (environment), over ~/.config/mt/config» o la ruta del fichero.
func (c Config) describeSource(variable, source string, fileHas bool) string {
	file := displayPath(c.Path)
	switch source {
	case SourceEnv:
		if fileHas {
			return variable + " (environment), over " + file
		}
		return variable + " (environment)"
	case SourceFile:
		return file
	}
	return "nowhere"
}

// whoamiError: el error que va en el sobre de --json. Solo el fallo de
// conexión es UNREACHABLE (y retryable); una respuesta que no es de Maker
// Tracker es UNEXPECTED_RESPONSE, que no se arregla reintentando.
func whoamiError(err error) *APIError {
	var apiErr *APIError
	var hinted *hintedError
	switch {
	case errors.As(err, &apiErr):
		return apiErr
	case errors.As(err, &hinted) && hinted.retryable:
		return &APIError{Code: "UNREACHABLE", Message: hinted.msg, Hint: hinted.hint, Retryable: true}
	case errors.As(err, &hinted):
		return &APIError{Code: "UNEXPECTED_RESPONSE", Message: hinted.msg, Hint: hinted.hint}
	}
	return &APIError{Code: "ERROR", Message: err.Error()}
}

// whoamiEnvelope: el sobre de la API, que aquí arma el propio mt.
type whoamiEnvelope struct {
	OK          bool      `json:"ok"`
	Data        whoami    `json:"data"`
	Summary     string    `json:"summary,omitempty"`
	Breadcrumbs []string  `json:"breadcrumbs,omitempty"`
	Warnings    []string  `json:"warnings,omitempty"`
	Error       *APIError `json:"error,omitempty"`
}

// print imprime el sobre en out. Si no es ok, sale con 1.
func (envl whoamiEnvelope) print(out io.Writer) error {
	encoder := json.NewEncoder(out)
	encoder.SetEscapeHTML(false)
	encoder.SetIndent("", "  ")
	if err := encoder.Encode(envl); err != nil {
		return err
	}
	if !envl.OK {
		return silentError{}
	}
	return nil
}

// displayPath abrevia el directorio personal con ~.
func displayPath(path string) string {
	home, err := os.UserHomeDir()
	if err != nil || home == "" {
		return path
	}
	if rel, err := filepath.Rel(home, path); err == nil && !strings.HasPrefix(rel, "..") {
		return filepath.Join("~", rel)
	}
	return path
}
