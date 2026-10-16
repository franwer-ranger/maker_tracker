# mt, el CLI de Maker Tracker. Solo biblioteca estándar de Go.
BIN := bin/mt

.PHONY: build install vet clean

build:
	go build -o $(BIN) ./cmd/mt

# Deja mt en $(go env GOPATH)/bin (normalmente ~/go/bin), que tiene que estar en el PATH.
install:
	go install ./cmd/mt
	@echo "mt instalado en $$(go env GOPATH)/bin/mt"

vet:
	go vet ./...

clean:
	rm -rf bin
