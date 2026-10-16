// mt es el CLI de Maker Tracker: así trabajan los agentes con la API desde la
// terminal, en el repo de cualquier proyecto.
package main

import (
	"os"

	"github.com/franwer-ranger/maker_tracker/cli/internal/mt"
)

func main() {
	os.Exit(mt.Main(os.Args[1:], os.Stdin, os.Stdout, os.Stderr))
}
