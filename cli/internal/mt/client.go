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
		return nil, usageErrorf("mt no sabe a qué instancia hablar. Configúralo con: mt setup <url> <token>")
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
		return nil, fmt.Errorf("no se puede conectar con %s: %v. ¿Está la instancia levantada y Tailscale encendido?", c.URL, err)
	}
	defer resp.Body.Close()

	if v := resp.Header.Get("X-MT-API-Version"); v != "" && v != APIVersion {
		c.VersionWarning = fmt.Sprintf("La instancia usa la API v%s y este mt conoce la v%s: actualiza mt (make -C cli install en el repo de Maker Tracker).", v, APIVersion)
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
		return nil, fmt.Errorf("%s no ha respondido como Maker Tracker (HTTP %d): %s", c.URL, resp.StatusCode, snippet)
	}
	return env, nil
}
