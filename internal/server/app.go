package server

import (
	"context"
	"database/sql"
	"errors"
	"net/http"
	"time"

	"github.com/labstack/echo/v4"
)

type App struct {
	echo           *echo.Echo
	server         *http.Server
	db             *sql.DB
	shutdownTimout time.Duration
}

func (a *App) Start() error {
	return a.server.ListenAndServe()
}

func (a *App) Shutdown(ctx context.Context) error {
	if a.shutdownTimout > 0 {
		var cancel context.CancelFunc
		ctx, cancel = context.WithTimeout(ctx, a.shutdownTimout)
		defer cancel()
	}

	var errs []error
	if err := a.echo.Shutdown(ctx); err != nil {
		errs = append(errs, err)
	}
	if err := a.db.Close(); err != nil {
		errs = append(errs, err)
	}
	return errors.Join(errs...)
}

func (a *App) Echo() *echo.Echo {
	return a.echo
}
