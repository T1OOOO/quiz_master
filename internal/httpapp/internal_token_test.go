package httpapp

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/labstack/echo/v4"
)

func TestInternalTokenMiddlewareFailsClosedWhenTokenMissing(t *testing.T) {
	e := echo.New()
	req := httptest.NewRequest(http.MethodGet, "/internal", nil)
	rec := httptest.NewRecorder()
	c := e.NewContext(req, rec)

	handler := InternalTokenMiddleware("")(func(c echo.Context) error {
		return c.NoContent(http.StatusOK)
	})

	if err := handler(c); err != nil {
		t.Fatalf("unexpected middleware error: %v", err)
	}
	if rec.Code != http.StatusServiceUnavailable {
		t.Fatalf("expected 503, got %d", rec.Code)
	}
}
