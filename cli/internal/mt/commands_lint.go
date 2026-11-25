package mt

import (
	"encoding/json"
	"net/url"
	"strings"
)

// mt doc lint (MT-123): va en su fichero para no tocar la lista de commands.go.
// Además deja escrito en mt doc --help el formato de una página de capacidad.
func init() {
	defer placeAfter("doc lint", "doc")
	if doc := findCommand([]string{"doc"}); doc != nil {
		doc.description += "\n\n" + pageFormat
	}
	def(&command{name: "doc lint", group: "Read", usage: "mt doc lint <page> | mt doc lint --all", maxArgs: 1,
		summary:     "Checks that a page will read well on the web before you call it done",
		description: "It reads the page with the same parser as the web and says whether it has an opening sentence, how many rules and questions it finds, the sections that will show as prose, the decisions and stories it cites that do not exist or are superseded, and the images that do not load or are not attachments of the page. It exits with 1 if there is any error (something that keeps the page from reading well); warnings only say it can be better. See the format with mt doc --help.",
		example:     "mt doc lint board",
		run: func(e *env) error {
			path := "/docs/lint"
			if !e.opts.has("all") {
				if e.arg(0) == "" {
					return usageHint("mt doc lint board or mt doc lint --all", "missing the page.")
				}
				path = "/docs/" + url.PathEscape(strings.ToLower(e.arg(0))) + "/lint"
			} else if e.arg(0) != "" {
				return usageHint("mt doc lint board or mt doc lint --all", "give a page or --all, not both.")
			}
			base, err := e.projectPath()
			if err != nil {
				return err
			}
			envl, err := e.client.Do("GET", base+path, nil, nil)
			if err != nil {
				return err
			}
			if err := e.render(envl); err != nil {
				return err
			}
			var data struct {
				Errors int `json:"errors"`
			}
			if json.Unmarshal(envl.Data, &data) == nil && data.Errors > 0 {
				return silentError{}
			}
			return nil
		}}, "all! every capability and cross-cutting page")
}

// pageFormat: cómo parte la web una página de capacidad (Page::Reading).
const pageFormat = `How the web reads a capability page:
  - Opening sentence: the first paragraph before any ## (or the first one of "## Qué hace hoy"). Without it, mt doc lint fails.
  - Screenshots: a line that is only an image attached to the page goes to the walkthrough, not to the text.
  - "## Cómo funciona": one rule per ### (title, then its text) or per bullet ("- **Title**: text"). Cited decisions (D-52) go to the side.
  - "## ¿Qué pasa si…?": one question per ### or per bullet ("- **¿…?** answer").
  - Those two only split into entries if they hold nothing else (no intro, closing or code); otherwise they show as prose, like any other ##.

  Una frase que dice qué hace la capacidad.

  ![c1-tablero.png](…)   <- the line mt attach board c1-tablero.png prints

  ## Cómo funciona
  - **Se ordena a mano**: arrastrando las tarjetas. D-12

  ## ¿Qué pasa si…?
  ### ¿… muevo una historia hecha?
  Vuelve a su sitio.

Check it with mt doc lint <page>.`
