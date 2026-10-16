package mt

import (
	"bufio"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"strings"
)

// Config es la instancia y el token: ~/.config/mt/config, con MT_URL y
// MT_TOKEN por encima.
type Config struct {
	URL   string
	Token string
}

func configPath() (string, error) {
	dir := os.Getenv("XDG_CONFIG_HOME")
	if dir == "" {
		home, err := os.UserHomeDir()
		if err != nil {
			return "", err
		}
		dir = filepath.Join(home, ".config")
	}
	return filepath.Join(dir, "mt", "config"), nil
}

// loadConfig lee el fichero (si existe) y aplica las variables de entorno.
func loadConfig() (Config, error) {
	var cfg Config
	path, err := configPath()
	if err != nil {
		return cfg, err
	}
	values, err := readKeyValues(path)
	if err != nil && !errors.Is(err, os.ErrNotExist) {
		return cfg, err
	}
	cfg.URL, cfg.Token = values["url"], values["token"]
	if v := os.Getenv("MT_URL"); v != "" {
		cfg.URL = v
	}
	if v := os.Getenv("MT_TOKEN"); v != "" {
		cfg.Token = v
	}
	cfg.URL = strings.TrimRight(cfg.URL, "/")
	return cfg, nil
}

func saveConfig(cfg Config) (string, error) {
	path, err := configPath()
	if err != nil {
		return "", err
	}
	if err := os.MkdirAll(filepath.Dir(path), 0o700); err != nil {
		return "", err
	}
	body := fmt.Sprintf("# mt: Maker Tracker instance and actor token. Don't share it.\nurl: %s\ntoken: %s\n", cfg.URL, cfg.Token)
	if err := os.WriteFile(path, []byte(body), 0o600); err != nil {
		return "", err
	}
	return path, os.Chmod(path, 0o600)
}

// readKeyValues lee líneas "clave: valor", ignorando
// comentarios y líneas vacías. Es el formato de config y de .mt.
func readKeyValues(path string) (map[string]string, error) {
	file, err := os.Open(path)
	if err != nil {
		return nil, err
	}
	defer file.Close()

	values := map[string]string{}
	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		if line == "" || strings.HasPrefix(line, "#") {
			continue
		}
		if key, value, ok := strings.Cut(line, ":"); ok {
			values[strings.TrimSpace(key)] = strings.TrimSpace(value)
		}
	}
	return values, scanner.Err()
}

// ProjectFile es el fichero que deja mt init en la raíz de un repo.
const ProjectFile = ".mt"

// findProject busca .mt hacia arriba desde dir. Devuelve la clave y el fichero.
func findProject(dir string) (string, string, error) {
	for {
		path := filepath.Join(dir, ProjectFile)
		if values, err := readKeyValues(path); err == nil {
			if key := strings.ToUpper(values["project"]); key != "" {
				return key, path, nil
			}
			return "", path, &hintedError{msg: fmt.Sprintf("%s has no \"project: KEY\" line.", path), hint: "run mt init PG at the root of the repo."}
		} else if !errors.Is(err, os.ErrNotExist) {
			return "", path, err
		}
		parent := filepath.Dir(dir)
		if parent == dir {
			return "", "", nil
		}
		dir = parent
	}
}
