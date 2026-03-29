package httpapp

import (
	"context"
	"fmt"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"syscall"
)

func Run(app *App, serviceName, port, env string) error {
	errCh := make(chan error, 1)
	go func() {
		slog.Info("starting service", "service", serviceName, "port", port, "env", env)
		errCh <- app.Start()
	}()

	sigCh := make(chan os.Signal, 1)
	signal.Notify(sigCh, os.Interrupt, syscall.SIGTERM)

	select {
	case sig := <-sigCh:
		slog.Info("shutdown signal received", "service", serviceName, "signal", sig.String())
		return app.Shutdown(context.Background())
	case err := <-errCh:
		if err == nil || err == http.ErrServerClosed {
			return nil
		}
		return fmt.Errorf("%s failed: %w", serviceName, err)
	}
}
