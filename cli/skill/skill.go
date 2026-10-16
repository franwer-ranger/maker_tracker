// Package skill embebe la skill de Maker Tracker para Claude Code, para que
// mt init --claude no dependa de tener el repo de Maker Tracker.
package skill

import _ "embed"

//go:embed SKILL.md
var Markdown []byte
