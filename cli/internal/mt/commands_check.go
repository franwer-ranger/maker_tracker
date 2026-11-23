package mt

// mt check (MT-79): va en su fichero para no tocar la lista de commands.go.
// Este init corre después del de commands.go (orden de los ficheros) y deja el
// comando detrás de mt decisions, en el grupo Read de mt help.
func init() {
	defer placeAfter("check", "decisions")
	def(&command{name: "check", group: "Read", usage: "mt check \"…\" | mt check --file f.md", maxArgs: 1,
		summary:     "Checks a proposal against the decisions, the stories and the brief before you build or propose it",
		description: "It returns up to 10 candidates, most relevant first: decisions (in force, or superseded and by which), stories of any state with their milestone, and fragments of the brief (above all Principios and Fuera de alcance), each with who, when, the why or an excerpt and the words that match. Whether the proposal clashes with them is for you to judge. Run it before creating a story, recording a decision or starting something that does not come from a ready story. --file - reads the proposal from standard input.",
		example:     "mt check \"avisar de historias casi listas\"",
		run: func(e *env) error {
			if e.opts.has("file") {
				text, err := readFileArg(e, e.opts.get("file"))
				if err != nil {
					return err
				}
				return e.projectCall("POST", "/check", nil, map[string]any{"text": text})
			}
			if e.arg(0) == "" {
				return usageHint("mt check \"what you want to do\" or mt check --file f.md", "missing the proposal.")
			}
			return e.projectCall("GET", "/check", map[string]string{"text": e.arg(0)}, nil)
		}}, "file file with the proposal (- for standard input)")
}

// placeAfter mueve el comando name detrás de after en la lista de commands.
func placeAfter(name, after string) {
	var cmd *command
	rest := commands[:0:0]
	for _, c := range commands {
		if c.name == name {
			cmd = c
		} else {
			rest = append(rest, c)
		}
	}
	for i, c := range rest {
		if c.name == after && cmd != nil {
			commands = append(rest[:i+1:i+1], append([]*command{cmd}, rest[i+1:]...)...)
			return
		}
	}
}
