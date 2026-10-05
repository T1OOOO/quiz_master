package httpapi

import (
	"context"
	"net/http/httptest"
	"quiz_master/next/server/internal/attempts"
	"quiz_master/next/server/internal/content"
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
func (selectedRouteService) CatalogForDifficulty(id, difficulty string) (attempts.Catalog, error) {
	if id != "q-selected" || difficulty != "hard" {
		return attempts.Catalog{}, attempts.ErrValidation
	}
	return attempts.Catalog{Quiz: content.PublicQuiz{QuizID: id, Questions: []content.PublicQuestion{{QuestionID: "q-hard", Difficulty: "hard"}}}}, nil
}
func (selectedRouteService) StartDifficultyQuiz(_ context.Context, _ string, id, difficulty string) (attempts.Attempt, error) {
	if id != "q-selected" || difficulty != "hard" {
		return attempts.Attempt{}, attempts.ErrValidation
	}
	return attempts.Attempt{AttemptID: "a-difficulty"}, nil
}
func (selectedRouteService) StartDifficultyRound(ctx context.Context, owner, id, difficulty string, _ int) (attempts.Attempt, error) {
	return selectedRouteService{}.StartDifficultyQuiz(ctx, owner, id, difficulty)
}
func (selectedRouteService) StartDifficultyPracticeRound(ctx context.Context, owner, id, difficulty string, round int) (attempts.Attempt, error) {
	return selectedRouteService{}.StartDifficultyRound(ctx, owner, id, difficulty, round)
}
func (selectedRouteService) StartPracticeQuiz(_ context.Context, _ string, id string) (attempts.Attempt, error) {
	if id != "q-selected" {
		return attempts.Attempt{}, attempts.ErrValidation
	}
	return attempts.Attempt{AttemptID: "a-practice-all"}, nil
}
func (selectedRouteService) StartDifficultyPracticeQuiz(_ context.Context, _ string, id, difficulty string) (attempts.Attempt, error) {
	if id != "q-selected" || difficulty != "hard" {
		return attempts.Attempt{}, attempts.ErrValidation
	}
	return attempts.Attempt{AttemptID: "a-practice-difficulty-all"}, nil
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
func TestDifficultySelectionRejectsMalformedValuesAndReachesBothEndpoints(t *testing.T) {
	h := AttemptRoutes(selectedRouteService{}, func(context.Context, string) (Principal, error) { return Principal{ID: "p_owner", Kind: "guest"}, nil })
	for _, path := range []string{"/v1/catalog?quiz_id=q-selected&difficulty=hard", "/v1/catalog?quiz_id=q-selected&difficulty=Hard", "/v1/catalog?quiz_id=q-selected&difficulty=hard&difficulty=easy"} {
		w := httptest.NewRecorder()
		h.ServeHTTP(w, httptest.NewRequest("GET", path, nil))
		want := 200
		if strings.Contains(path, "Hard") || strings.Count(path, "difficulty=") > 1 {
			want = 400
		}
		if w.Code != want {
			t.Fatalf("%s status %d want %d", path, w.Code, want)
		}
	}
	for _, body := range []struct {
		value string
		want  int
	}{{`{"quiz_id":"q-selected","difficulty":"hard"}`, 201}, {`{"quiz_id":"q-selected","difficulty":""}`, 400}, {`{"quiz_id":"q-selected","difficulty":"unknown"}`, 400}, {`{"quiz_id":"q-selected","difficulty":null}`, 400}} {
		request := httptest.NewRequest("POST", "/v1/attempts", strings.NewReader(body.value))
		request.Header.Set("Content-Type", "application/json")
		request.Header.Set("Authorization", "Bearer token")
		w := httptest.NewRecorder()
		h.ServeHTTP(w, request)
		if w.Code != body.want {
			t.Fatalf("%s status %d want %d", body.value, w.Code, body.want)
		}
	}
}

func TestPracticeWholePackRequiresQuizAndAcceptsOmittedRound(t *testing.T) {
	h := AttemptRoutes(selectedRouteService{}, func(context.Context, string) (Principal, error) { return Principal{ID: "p_owner", Kind: "guest"}, nil })
	for _, tt := range []struct{ body, want string }{
		{`{"quiz_id":"q-selected","mode":"practice"}`, "a-practice-all"},
		{`{"quiz_id":"q-selected","difficulty":"hard","mode":"practice"}`, "a-practice-difficulty-all"},
		{`{"mode":"practice"}`, ""},
	} {
		r := httptest.NewRequest("POST", "/v1/attempts", strings.NewReader(tt.body))
		r.Header.Set("Content-Type", "application/json")
		r.Header.Set("Authorization", "Bearer token")
		w := httptest.NewRecorder()
		h.ServeHTTP(w, r)
		if tt.want == "" {
			if w.Code != 400 {
				t.Fatalf("%s status %d", tt.body, w.Code)
			}
		} else if w.Code != 201 || !strings.Contains(w.Body.String(), tt.want) {
			t.Fatalf("%s status=%d body=%s", tt.body, w.Code, w.Body.String())
		}
	}
}
