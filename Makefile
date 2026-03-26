.PHONY: test test-coverage test-backend test-frontend help db-init db-reset run-api stop-api run-client run-client-web run-client-windows run-dev stop-dev stop-all

help:
	@echo "Available targets:"
	@echo "  test            - Run all tests (backend + frontend)"
	@echo "  test-backend   - Run Go backend tests"
	@echo "  test-frontend  - Run Flutter frontend tests"
	@echo "  test-coverage  - Run tests with coverage report"

test: test-backend test-frontend

test-backend:
	@echo "Running backend tests..."
	cd . && go test -v ./...

test-backend-coverage:
	@echo "Running backend tests with coverage..."
	cd . && go test -coverprofile=coverage_backend.out ./...
	@echo "Coverage report generated: coverage_backend.out"
	@echo "View with: go tool cover -html=coverage_backend.out"

test-frontend:
	@echo "Running Flutter tests..."
	cd flutter && flutter test

test-frontend-coverage:
	@echo "Running Flutter tests with coverage..."
	cd flutter && flutter test --coverage

test-coverage: test-backend-coverage test-frontend-coverage
	@echo "All coverage reports generated"

db-init:
	go run ./cmd/dbtool -action init

db-reset:
	go run ./cmd/dbtool -action reset

run-api:
	go run ./cmd/api

stop-api:
	powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\stop-api.ps1

run-client:
	cd flutter && flutter pub get && flutter run -d chrome --web-port 8091 --dart-define=SERVER_BASE_URL=http://localhost:8090 --dart-define=API_BASE_URL=http://localhost:8090/api

run-client-web:
	powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\run-client-web.ps1

run-client-windows:
	powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\run-client-windows.ps1

run-dev:
	powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\run-dev.ps1

stop-dev:
	powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\stop-dev.ps1

stop-all:
	powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\stop-all.ps1
