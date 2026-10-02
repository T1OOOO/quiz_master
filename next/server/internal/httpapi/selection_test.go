package httpapi

import (
	"context"
	"net/http/httptest"
	"quiz_master/next/server/internal/attempts"
	"strings"
	"testing"
)

type selectedRouteService struct{ routeAttemptService }

func (selectedRouteService) CatalogFor(id string) (attempts.Catalog, error) {
	if id != "q-selected" {
		return attempts.Catalog{}, attempts.ErrValidation
	}
	c := attempts.Catalog{}
	c.Quiz.QuizID = id
	return c, nil
}
func (selectedRouteService) StartQuiz(_ context.Context, _ string, id string) (attempts.Attempt, error) {
	if id != "q-selected" {
		return attempts.Attempt{}, attempts.ErrValidation
	}
	return attempts.Attempt{AttemptID: "a-selected"}, nil
}
func TestSelectedQuizReachesCatalogAndAttempt(t *testing.T) {
	h := AttemptRoutes(selectedRouteService{}, func(context.Context, string) (Principal, error) { return Principal{ID: "p_owner", Kind: "guest"}, nil })
	w := httptest.NewRecorder()
	h.ServeHTTP(w, httptest.NewRequest("GET", "/v1/catalog?quiz_id=q-selected", nil))
	if w.Code != 200 || !strings.Contains(w.Body.String(), "q-selected") {
		t.Fatalf("selected catalog: %d %s", w.Code, w.Body.String())
	}
	r := httptest.NewRequest("POST", "/v1/attempts", strings.NewReader(`{"quiz_id":"q-selected"}`))
	r.Header.Set("Content-Type", "application/json")
	r.Header.Set("Authorization", "Bearer token")
	w = httptest.NewRecorder()
	h.ServeHTTP(w, r)
	if w.Code != 201 || !strings.Contains(w.Body.String(), "a-selected") {
		t.Fatalf("selected start: %d %s", w.Code, w.Body.String())
	}
}
