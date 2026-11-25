package mt

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"math"
	"mime/multipart"
	"net/http"
	"net/url"
	"os"
	"path/filepath"
	"strconv"
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

// Upload es el cuerpo de una subida (mt attach): el archivo Path en el campo
// "file" de un multipart/form-data, en vez de JSON, y Fields como campos de texto
// del mismo formulario (alt, MT-122).
type Upload struct {
	Path   string
	Fields map[string]string
}

// UploadTimeout es lo que espera una subida: un vídeo de 100 MB no cabe en 20 s.
const UploadTimeout = 10 * time.Minute

// MaxUploadSize es el máximo que admite la instancia por archivo (Attachable::MAX_SIZE).
const MaxUploadSize = 100 << 20

// multipartBody arma el formulario con el archivo, en memoria: por eso
// rechaza antes, sin leerlo, lo que pasa de MaxUploadSize, con el mismo
// mensaje que daría la API.
func multipartBody(up Upload) (io.Reader, string, error) {
	file, err := os.Open(up.Path)
	if err != nil {
		return nil, "", usageHint("check the path.", "can't read %s: %v.", up.Path, err)
	}
	defer file.Close()
	if info, err := file.Stat(); err == nil && info.Size() > MaxUploadSize {
		return nil, "", usageHint("attach images, videos, PDF, text or archives of up to 100 MB.",
			"%s is %s: the limit is %s.", filepath.Base(up.Path), humanSize(info.Size()), humanSize(MaxUploadSize))
	}
	var buf bytes.Buffer
	form := multipart.NewWriter(&buf)
	for name, value := range up.Fields {
		if err := form.WriteField(name, value); err != nil {
			return nil, "", err
		}
	}
	part, err := form.CreateFormFile("file", filepath.Base(up.Path))
	if err != nil {
		return nil, "", err
	}
	if _, err := io.Copy(part, file); err != nil {
		return nil, "", err
	}
	if err := form.Close(); err != nil {
		return nil, "", err
	}
	return &buf, form.FormDataContentType(), nil
}

// humanSize escribe un tamaño como la API (number_to_human_size): "120 MB", "1.5 GB".
func humanSize(bytes int64) string {
	units := []string{"Bytes", "KB", "MB", "GB", "TB"}
	size, unit := float64(bytes), 0
	for size >= 1024 && unit < len(units)-1 {
		size /= 1024
		unit++
	}
	if unit == 0 {
		return fmt.Sprintf("%d Bytes", bytes)
	}
	return strconv.FormatFloat(roundSignificant(size, 3), 'f', -1, 64) + " " + units[unit]
}

// roundSignificant redondea a n cifras significativas (120.4 → 120, 1.234 → 1.23).
func roundSignificant(x float64, n int) float64 {
	scale := math.Pow(10, float64(n-1-int(math.Floor(math.Log10(x)))))
	return math.Round(x*scale) / scale
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
	contentType := "application/json"
	httpClient := c.HTTP
	if up, ok := body.(Upload); ok {
		var err error
		if reader, contentType, err = multipartBody(up); err != nil {
			return nil, err
		}
		httpClient = &http.Client{Timeout: UploadTimeout, Transport: c.HTTP.Transport}
	} else if body != nil {
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
		req.Header.Set("Content-Type", contentType)
	}
	if c.Token != "" {
		req.Header.Set("Authorization", "Bearer "+c.Token)
	}

	resp, err := httpClient.Do(req)
	if err != nil {
		return nil, &hintedError{msg: fmt.Sprintf("can't connect to %s: %v.", c.URL, err), hint: "check that the instance is up and Tailscale is on.", retryable: true}
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
