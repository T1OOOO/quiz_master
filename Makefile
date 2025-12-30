.PHONY: run test build tidy

run:
	bash start.sh

test:
	go test ./internal/... -v

build:
	go build -o bin/server cmd/api/main.go

tidy:
	go mod tidy
