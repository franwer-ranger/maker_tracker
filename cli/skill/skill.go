// Package skill embebe las skills de Maker Tracker para Claude Code, para que
// mt init --claude no dependa de tener el repo de Maker Tracker.
package skill

import _ "embed"

// Markdown es la skill maker-tracker.
//
//go:embed SKILL.md
var Markdown []byte

// Daily es la skill daily (/daily, MT-42).
//
//go:embed daily/SKILL.md
var Daily []byte

// Skill es una skill instalable: su carpeta en .claude/skills/ y su contenido.
type Skill struct {
	Name    string
	Content []byte
}

// All son las skills que instala mt, la principal primero.
func All() []Skill {
	return []Skill{{"maker-tracker", Markdown}, {"daily", Daily}}
}
