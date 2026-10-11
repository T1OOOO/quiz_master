package server

import (
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"testing"

	"github.com/labstack/echo/v4"
)

func TestWebHandler(t *testing.T) {
	dir := t.TempDir()
	if err := os.MkdirAll(filepath.Join(dir, "assets"), 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(dir, "index.html"), []byte("INDEX"), 0o644); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(dir, "main.dart.js"), []byte("JS"), 0o644); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(dir, "assets", "a.txt"), []byte("ASSET"), 0o644); err != nil {
		t.Fatal(err)
	}

	e := echo.New()
	e.GET("/*", webHandler(dir))

	cases := []struct {
		path string
		code int
		body string
	}{
		{"/", http.StatusOK, "INDEX"},
		{"/main.dart.js", http.StatusOK, "JS"},
		{"/assets/a.txt", http.StatusOK, "ASSET"},
		{"/some/client/route", http.StatusOK, "INDEX"},
		{"/assets", http.StatusOK, "INDEX"},
		{"/../../etc/passwd", http.StatusOK, "INDEX"},
		{"/api/nope", http.StatusNotFound, ""},
	}
	for _, tc := range cases {
		rec := httptest.NewRecorder()
		e.ServeHTTP(rec, httptest.NewRequest(http.MethodGet, tc.path, nil))
		if rec.Code != tc.code {
			t.Errorf("%s: code %d, want %d", tc.path, rec.Code, tc.code)
		}
		if tc.body != "" && rec.Body.String() != tc.body {
			t.Errorf("%s: body %q, want %q", tc.path, rec.Body.String(), tc.body)
		}
	}
}
