# mt, el CLI de Maker Tracker. Solo biblioteca estándar de Go.
BIN := bin/mt

.PHONY: build install linux vet clean

build:
	go build -o $(BIN) ./cmd/mt

# Deja mt en $(go env GOPATH)/bin (normalmente ~/go/bin), que tiene que estar en el PATH.
install:
	go install ./cmd/mt
	@echo "mt instalado en $$(go env GOPATH)/bin/mt"

# mt para Linux (la torre, donde bin/deploy llama a `mt deployed`). Cruza desde
# cualquier máquina; la arquitectura es la de `uname -m` en la torre:
#   x86_64 -> GOARCH=amd64 (por defecto) · aarch64 -> GOARCH=arm64
#   make -C cli linux GOARCH=arm64   ->   cli/bin/mt-linux-arm64
# Copiarlo es manual (docs/SELF_HOSTING.md): este objetivo no toca ninguna máquina.
GOARCH ?= amd64
linux:
	GOOS=linux GOARCH=$(GOARCH) CGO_ENABLED=0 go build -o $(BIN)-linux-$(GOARCH) ./cmd/mt
	@echo "built $(BIN)-linux-$(GOARCH)"

vet:
	go vet ./...

clean:
	rm -rf bin
