package httpapp

import (
	"context"
	"errors"
	"net/http"
	"time"

	"github.com/labstack/echo/v4"
)

type App struct {
	echo            *echo.Echo
	server          *http.Server
	shutdownTimeout time.Duration
	cleanup         func() error
}

func New(e *echo.Echo, handler http.Handler, port string, shutdownTimeout time.Duration, cleanup func() error) *App {
	if handler == nil {
		handler = e
	}
	return &App{
		echo: e,
		server: &http.Server{
			Addr:              ":" + port,
			Handler:           handler,
			ReadHeaderTimeout: 5 * time.Second,
		},
		shutdownTimeout: shutdownTimeout,
		cleanup:         cleanup,
	}
}

func (a *App) Start() error {
	return a.server.ListenAndServe()
}

func (a *App) Shutdown(ctx context.Context) error {
	if a.shutdownTimeout > 0 {
		var cancel context.CancelFunc
		ctx, cancel = context.WithTimeout(ctx, a.shutdownTimeout)
		defer cancel()
	}

	var errs []error
	if err := a.echo.Shutdown(ctx); err != nil {
		errs = append(errs, err)
	}
	if a.cleanup != nil {
		if err := a.cleanup(); err != nil {
			errs = append(errs, err)
		}
	}
	return errors.Join(errs...)
}
