package mt

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strings"
	"time"
)

// APIVersion es la versión de la API que conoce este binario.
const APIVersion = "1"

// Envelope es el sobre de todas las respuestas de la API.
type Envelope struct {
	OK          bool            `json:"ok"`
	Data        json.RawMessage `json:"data,omitempty"`
	Summary     string          `json:"summary,omitempty"`
	Breadcrumbs []string        `json:"breadcrumbs,omitempty"`
	Warnings    []string        `json:"warnings,omitempty"`
	Error       *APIError       `json:"error,omitempty"`

	raw []byte
}

type APIError struct {
	Code      string `json:"code"`
	Message   string `json:"message"`
	Hint      string `json:"hint,omitempty"`
	Retryable bool   `json:"retryable"`
}

func (e *APIError) Error() string { return e.Message }

// Markdown devuelve data.markdown si lo hay.
func (e *Envelope) Markdown() string {
	var data struct {
		Markdown string `json:"markdown"`
	}
	if len(e.Data) > 0 && json.Unmarshal(e.Data, &data) == nil {
		return data.Markdown
	}
	return ""
}

type Client struct {
	URL   string
	Token string
	HTTP  *http.Client
	// VersionWarning se rellena si la API responde con una versión desconocida.
	VersionWarning string
}

func newClient(cfg Config) *Client {
	return &Client{URL: cfg.URL, Token: cfg.Token, HTTP: &http.Client{Timeout: 20 * time.Second}}
}

// Do hace una llamada y devuelve el sobre. Un error de la API (ok: false) no
// es un error de Go: viene en Envelope.Error.
func (c *Client) Do(method, path string, query url.Values, body any) (*Envelope, error) {
	if c.URL == "" {
		return nil, usageHint("mt setup <url> <token>", "mt does not know which instance to talk to.")
	}
	target := c.URL + path
	if len(query) > 0 {
		target += "?" + query.Encode()
	}

	var reader io.Reader
	if body != nil {
		payload, err := json.Marshal(body)
		if err != nil {
			return nil, err
		}
		reader = bytes.NewReader(payload)
	}
	req, err := http.NewRequest(method, target, reader)
	if err != nil {
		return nil, err
	}
	req.Header.Set("Accept", "application/json")
	req.Header.Set("User-Agent", "mt/"+Version)
	if body != nil {
		req.Header.Set("Content-Type", "application/json")
	}
	if c.Token != "" {
		req.Header.Set("Authorization", "Bearer "+c.Token)
	}

	resp, err := c.HTTP.Do(req)
	if err != nil {
		return nil, &hintedError{msg: fmt.Sprintf("can't connect to %s: %v.", c.URL, err), hint: "check that the instance is up and Tailscale is on."}
	}
	defer resp.Body.Close()

	if v := resp.Header.Get("X-MT-API-Version"); v != "" && v != APIVersion {
		c.VersionWarning = fmt.Sprintf("the instance speaks API v%s and this mt knows v%s: update mt (make -C cli install in the Maker Tracker repo).", v, APIVersion)
	}

	raw, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}
	env := &Envelope{raw: raw}
	if err := json.Unmarshal(raw, env); err != nil || (!env.OK && env.Error == nil) {
		snippet := strings.TrimSpace(string(raw))
		if len(snippet) > 200 {
			snippet = snippet[:200] + "…"
		}
		return nil, &hintedError{msg: fmt.Sprintf("%s did not answer like Maker Tracker (HTTP %d): %s", c.URL, resp.StatusCode, snippet), hint: "check the url with mt setup <url> <token>."}
	}
	return env, nil
}
