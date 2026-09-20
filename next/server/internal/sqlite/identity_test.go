package sqlite

import (
	"bytes"
	"context"
	"database/sql"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"net/http/httptest"
	"reflect"
	"strings"
	"sync"
	"testing"
	"time"

	_ "modernc.org/sqlite"
	"quiz_master/next/server/internal/attempts"
	"quiz_master/next/server/internal/httpapi"
	"quiz_master/next/server/internal/identity"
)

func TestIdentityGuestAuthenticatesAfterDatabaseReopen(t *testing.T) {
	path := "file:" + t.TempDir() + "/quiz.db"
	db, err := sql.Open("sqlite", path)
	if err != nil {
		t.Fatal(err)
	}
	if err = Apply(context.Background(), db); err != nil {
		t.Fatal(err)
	}
	s := NewIdentity(db, func() time.Time { return time.Date(2026, 9, 21, 0, 0, 0, 0, time.UTC) }, identity.NewTokenSource(nil))
	guest, err := s.CreateGuestSession(context.Background(), "local guest")
	if err != nil {
		t.Fatal(err)
	}
	if err = db.Close(); err != nil {
		t.Fatal(err)
	}
	db, err = sql.Open("sqlite", path)
	if err != nil {
		t.Fatal(err)
	}
	defer db.Close()
	s = NewIdentity(db, func() time.Time { return time.Date(2026, 9, 21, 1, 0, 0, 0, time.UTC) }, identity.NewTokenSource(nil))
	got, err := s.Authenticate(context.Background(), guest.Token)
	if err != nil || got.ID != guest.Principal.ID {
		t.Fatalf("guest=%+v got=%+v err=%v", guest, got, err)
	}
}

func TestNewAttemptsRejectsMissingConfiguredManifest(t *testing.T) {
	db, err := sql.Open("sqlite", "file:"+t.TempDir()+"/quiz.db")
	if err != nil {
		t.Fatal(err)
	}
	defer db.Close()
	if err = Apply(context.Background(), db); err != nil {
		t.Fatal(err)
	}
	if _, err := NewAttempts(db, "../../../content/home-alone-1-part-1/bundle.json", "missing-manifest.json", "../../../contracts/quiz-contract/v1/schemas", 30*time.Minute); err == nil {
		t.Fatal("accepted missing configured manifest")
	}
	if _, err := NewAttempts(db, "../../../content/home-alone-1-part-1/draft.json", "../../../content/home-alone-1-part-1/manifest.json", "../../../contracts/quiz-contract/v1/schemas", 30*time.Minute); err == nil {
		t.Fatal("accepted draft as controlled bundle")
	}
}

func TestSQLiteHTTPJourneySurvivesReopen(t *testing.T) {
	path := "file:" + t.TempDir() + "/http.db"
	db, err := sql.Open("sqlite", path)
	if err != nil {
		t.Fatal(err)
	}
	if err = Apply(context.Background(), db); err != nil {
		t.Fatal(err)
	}
	newRoutes := func() http.Handler {
		a, _ := NewAttempts(db, "../../../content/home-alone-1-part-1/bundle.json", "../../../content/home-alone-1-part-1/manifest.json", "../../../contracts/quiz-contract/v1/schemas", 30*time.Minute)
		i := NewIdentity(db, nil, identity.NewTokenSource(nil))
		return httpapi.Routes(a, func(c context.Context, t string) (httpapi.Principal, error) {
			p, e := i.Authenticate(c, t)
			return httpapi.Principal{ID: p.ID, Kind: p.Kind}, e
		}, i.CreateGuestSession)
	}
	h := newRoutes()
	call := func(method, path, token string, body any) *httptest.ResponseRecorder {
		var b *bytes.Reader
		if body == nil {
			b = bytes.NewReader(nil)
		} else {
			raw, _ := json.Marshal(body)
			b = bytes.NewReader(raw)
		}
		r := httptest.NewRequest(method, path, b)
		if body != nil {
			r.Header.Set("Content-Type", "application/json")
		}
		if token != "" {
			r.Header.Set("Authorization", "Bearer "+token)
		}
		w := httptest.NewRecorder()
		h.ServeHTTP(w, r)
		return w
	}
	w := call("POST", "/v1/guests", "", map[string]string{"display_name": "guest"})
	if w.Code != 201 {
		t.Fatal(w.Code, w.Body.String())
	}
	var guest struct {
		Token string `json:"token"`
	}
	json.NewDecoder(w.Body).Decode(&guest)
	w = call("GET", "/v1/catalog", "", nil)
	if w.Code != 200 {
		t.Fatal(w.Code)
	}
	for _, marker := range []string{"private_grading", "accepted_variants", "correct_option_id", "correct_option_ids", "published_bundle", `"draft"`} {
		if strings.Contains(w.Body.String(), marker) {
			t.Fatalf("catalog leaks %q", marker)
		}
	}
	w = call("POST", "/v1/attempts", guest.Token, map[string]any{})
	if w.Code != 201 {
		t.Fatal(w.Code, w.Body.String())
	}
	var a attempts.Attempt
	json.NewDecoder(w.Body).Decode(&a)
	q := a.QuestionSnapshots[0]
	option := q.OptionOrder[0]
	req := attempts.AnswerRequest{QuestionID: q.QuestionID, QuestionRevision: q.QuestionRevision, Answer: attempts.Answer{OptionID: &option}, IdempotencyKey: "one"}
	req.PayloadDigest, _ = attempts.PayloadDigest(a.AttemptID, a.ParticipantID, req)
	w = call("POST", "/v1/attempts/"+a.AttemptID+"/answers", guest.Token, req)
	if w.Code != 200 {
		t.Fatal(w.Code, w.Body.String())
	}
	w = call("POST", "/v1/attempts/"+a.AttemptID+"/finish", guest.Token, map[string]any{})
	if w.Code != 200 {
		t.Fatal(w.Code, w.Body.String())
	}
	w = call("GET", "/v1/attempts/"+a.AttemptID+"/reveals", guest.Token, nil)
	if w.Code != 200 {
		t.Fatal(w.Code, w.Body.String())
	}
	if err = db.Close(); err != nil {
		t.Fatal(err)
	}
	db, err = sql.Open("sqlite", path)
	if err != nil {
		t.Fatal(err)
	}
	defer db.Close()
	h = newRoutes()
	w = call("GET", "/v1/history", guest.Token, nil)
	if w.Code != 200 {
		t.Fatal(w.Code, w.Body.String())
	}
}

func TestAttemptsStartAndSubmitUsePinnedSQLiteRows(t *testing.T) {
	path := "file:" + t.TempDir() + "/quiz.db"
	db, err := sql.Open("sqlite", path)
	if err != nil {
		t.Fatal(err)
	}
	defer db.Close()
	if err = Apply(context.Background(), db); err != nil {
		t.Fatal(err)
	}
	s, err := NewAttempts(db, "../../../content/home-alone-1-part-1/bundle.json", "../../../content/home-alone-1-part-1/manifest.json", "../../../contracts/quiz-contract/v1/schemas", 30*time.Minute)
	if err != nil {
		t.Fatal(err)
	}
	var pinned int
	if err = db.QueryRow("select count(*) from attempt_bundles").Scan(&pinned); err != nil || pinned != 1 {
		t.Fatalf("bundle pin count=%d err=%v", pinned, err)
	}
	owner := "p_0123456789abcdef0123456789abcdef"
	if _, err = db.Exec("insert into participants(id,kind,display_name,created_at,updated_at) values(?,?,?,?,?)", owner, "guest", "guest", "2026-09-21T00:00:00Z", "2026-09-21T00:00:00Z"); err != nil {
		t.Fatal(err)
	}
	a, err := s.Start(context.Background(), owner)
	if err != nil {
		t.Fatal(err)
	}
	q := a.QuestionSnapshots[0]
	option := s.bundle.PrivateGrading[q.QuestionID].CorrectOptionID
	r := attempts.AnswerRequest{QuestionID: q.QuestionID, QuestionRevision: q.QuestionRevision, Answer: attempts.Answer{OptionID: &option}, IdempotencyKey: "one"}
	r.PayloadDigest, _ = attempts.PayloadDigest(a.AttemptID, a.ParticipantID, r)
	receipt, err := s.Submit(context.Background(), owner, a.AttemptID, r)
	if err != nil {
		t.Fatal(err)
	}
	replay, err := s.Submit(context.Background(), owner, a.AttemptID, r)
	if err != nil || replay != receipt {
		t.Fatalf("replay=%+v receipt=%+v err=%v", replay, receipt, err)
	}
	if _, err = db.Exec("update attempts set deadline_at=? where id=?", time.Now().UTC().Add(-time.Second).Format(time.RFC3339Nano), a.AttemptID); err != nil {
		t.Fatal(err)
	}
	lateReplay, err := s.Submit(context.Background(), owner, a.AttemptID, r)
	if err != nil || lateReplay != receipt {
		t.Fatalf("deadline replay=%+v err=%v", lateReplay, err)
	}
	changed := r
	otherOption := ""
	for _, candidate := range q.OptionOrder {
		if candidate != *r.Answer.OptionID {
			otherOption = candidate
			break
		}
	}
	if otherOption == "" {
		t.Fatal("no distinct option")
	}
	changed.Answer = attempts.Answer{OptionID: &otherOption}
	changed.PayloadDigest, _ = attempts.PayloadDigest(a.AttemptID, a.ParticipantID, changed)
	if _, err = s.Submit(context.Background(), owner, a.AttemptID, changed); !errors.Is(err, attempts.ErrConflict) {
		t.Fatalf("same-key conflict=%v", err)
	}
	foreign := "p_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
	for _, probe := range []attempts.AnswerRequest{r, changed} {
		if _, err = s.Submit(context.Background(), foreign, a.AttemptID, probe); !errors.Is(err, attempts.ErrForbidden) {
			t.Fatalf("foreign replay=%v", err)
		}
	}
	for _, key := range []string{"", strings.Repeat("k", 201)} {
		bad := r
		bad.IdempotencyKey = key
		if _, err = s.Submit(context.Background(), owner, a.AttemptID, bad); !errors.Is(err, attempts.ErrValidation) {
			t.Fatalf("key %q err=%v", key, err)
		}
	}
	stale := r
	stale.QuestionRevision.Number++
	stale.IdempotencyKey = "stale"
	stale.PayloadDigest, _ = attempts.PayloadDigest(a.AttemptID, a.ParticipantID, stale)
	if _, err = s.Submit(context.Background(), owner, a.AttemptID, stale); !errors.Is(err, attempts.ErrRevision) {
		t.Fatalf("stale=%v", err)
	}
	if _, err = s.GetHistory(context.Background(), "p_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", a.AttemptID); !errors.Is(err, attempts.ErrForbidden) {
		t.Fatalf("foreign history=%v", err)
	}
	if _, err = s.Reveals(context.Background(), "p_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", a.AttemptID); !errors.Is(err, attempts.ErrForbidden) {
		t.Fatalf("foreign reveals=%v", err)
	}
	late, err := s.Start(context.Background(), owner)
	if err != nil {
		t.Fatal(err)
	}
	if _, err = db.Exec("update attempts set deadline_at=? where id=?", time.Now().UTC().Add(-time.Second).Format(time.RFC3339Nano), late.AttemptID); err != nil {
		t.Fatal(err)
	}
	lq := late.QuestionSnapshots[0]
	lo := s.bundle.PrivateGrading[lq.QuestionID].CorrectOptionID
	lr := attempts.AnswerRequest{QuestionID: lq.QuestionID, QuestionRevision: lq.QuestionRevision, Answer: attempts.Answer{OptionID: &lo}, IdempotencyKey: "late"}
	lr.PayloadDigest, _ = attempts.PayloadDigest(late.AttemptID, late.ParticipantID, lr)
	if _, err = s.Submit(context.Background(), owner, late.AttemptID, lr); !errors.Is(err, attempts.ErrDeadline) {
		t.Fatalf("deadline=%v", err)
	}
	// Simulate a restart after the configured source bundle was replaced or is
	// unavailable: completion must use the bundle pinned at attempt start.
	restarted, err := NewAttempts(db, "missing-source.json", "missing-manifest.json", "../../../contracts/quiz-contract/v1/schemas", 30*time.Minute)
	if err != nil {
		t.Fatalf("persisted restart: %v", err)
	}
	f, err := restarted.Finish(context.Background(), owner, a.AttemptID)
	if err != nil || f.Status != "finished" || f.ServerScore != 1 || len(f.History) != 1 {
		t.Fatalf("finish=%+v err=%v", f, err)
	}
	again, err := restarted.Finish(context.Background(), owner, a.AttemptID)
	if err != nil || !reflect.DeepEqual(again, f) {
		t.Fatalf("finish replay=%+v first=%+v err=%v", again, f, err)
	}
	postFinish, err := restarted.Submit(context.Background(), owner, a.AttemptID, r)
	if err != nil || postFinish != receipt {
		t.Fatalf("post-finish replay=%+v receipt=%+v err=%v", postFinish, receipt, err)
	}
	start := make(chan struct{})
	results := make(chan attempts.Finish, 4)
	finishErrs := make(chan error, 4)
	var wg sync.WaitGroup
	for range 4 {
		wg.Add(1)
		go func() {
			defer wg.Done()
			<-start
			got, e := restarted.Finish(context.Background(), owner, a.AttemptID)
			results <- got
			finishErrs <- e
		}()
	}
	close(start)
	wg.Wait()
	close(results)
	close(finishErrs)
	for e := range finishErrs {
		if e != nil {
			t.Fatal(e)
		}
	}
	for got := range results {
		if !reflect.DeepEqual(got, f) {
			t.Fatalf("concurrent finish=%+v first=%+v", got, f)
		}
	}
	race, err := s.Start(context.Background(), owner)
	if err != nil {
		t.Fatal(err)
	}
	rq := race.QuestionSnapshots[0]
	ro := s.bundle.PrivateGrading[rq.QuestionID].CorrectOptionID
	rr := attempts.AnswerRequest{QuestionID: rq.QuestionID, QuestionRevision: rq.QuestionRevision, Answer: attempts.Answer{OptionID: &ro}, IdempotencyKey: "race"}
	rr.PayloadDigest, _ = attempts.PayloadDigest(race.AttemptID, race.ParticipantID, rr)
	gate := make(chan struct{})
	submitErr := make(chan error, 1)
	finishErr := make(chan error, 1)
	go func() { <-gate; _, e := s.Submit(context.Background(), owner, race.AttemptID, rr); submitErr <- e }()
	go func() { <-gate; _, e := s.Finish(context.Background(), owner, race.AttemptID); finishErr <- e }()
	close(gate)
	se := <-submitErr
	fe := <-finishErr
	if se != nil && !errors.Is(se, attempts.ErrValidation) {
		t.Fatalf("race submit=%v", se)
	}
	if fe != nil && !errors.Is(fe, attempts.ErrValidation) {
		t.Fatalf("race finish=%v", fe)
	}
	final, err := s.Finish(context.Background(), owner, race.AttemptID)
	if se == nil {
		if err != nil || len(final.History) != 1 {
			t.Fatalf("accepted answer omitted: %+v %v", final, err)
		}
	} else if err == nil {
		t.Fatal("finish succeeded without accepted answer")
	}
	reveals, err := restarted.Reveals(context.Background(), owner, a.AttemptID)
	if err != nil || len(reveals) != 1 || reveals[0].QuestionID != q.QuestionID {
		t.Fatalf("reveals=%+v err=%v", reveals, err)
	}
	if err = db.Close(); err != nil {
		t.Fatal(err)
	}
	db, err = sql.Open("sqlite", path)
	if err != nil {
		t.Fatal(err)
	}
	defer db.Close()
	s, err = NewAttempts(db, "../../../content/home-alone-1-part-1/bundle.json", "../../../content/home-alone-1-part-1/manifest.json", "../../../contracts/quiz-contract/v1/schemas", 30*time.Minute)
	if err != nil {
		t.Fatal(err)
	}
	got, err := s.GetHistory(context.Background(), owner, a.AttemptID)
	if err != nil || got.ServerScore != f.ServerScore || len(got.History) != 1 {
		t.Fatalf("history=%+v err=%v", got, err)
	}
	ordered, err := s.Start(context.Background(), owner)
	if err != nil {
		t.Fatal(err)
	}
	for _, index := range []int{1, 0} {
		q := ordered.QuestionSnapshots[index]
		o := s.bundle.PrivateGrading[q.QuestionID].CorrectOptionID
		req := attempts.AnswerRequest{QuestionID: q.QuestionID, QuestionRevision: q.QuestionRevision, Answer: attempts.Answer{OptionID: &o}, IdempotencyKey: fmt.Sprintf("order-%d", index)}
		req.PayloadDigest, _ = attempts.PayloadDigest(ordered.AttemptID, ordered.ParticipantID, req)
		if _, err = s.Submit(context.Background(), owner, ordered.AttemptID, req); err != nil {
			t.Fatal(err)
		}
	}
	of, err := s.Finish(context.Background(), owner, ordered.AttemptID)
	if err != nil {
		t.Fatal(err)
	}
	or, err := s.Reveals(context.Background(), owner, ordered.AttemptID)
	if err != nil || len(or) != 2 || or[0].QuestionID != of.History[0].QuestionID || or[0].QuestionID != ordered.QuestionSnapshots[0].QuestionID {
		t.Fatalf("ordered history=%+v reveals=%+v err=%v", of.History, or, err)
	}
	if list, err := s.ListHistory(context.Background(), owner); err != nil || len(list) < 1 {
		t.Fatalf("list=%+v err=%v", list, err)
	}
	if reveals, err := s.Reveals(context.Background(), owner, a.AttemptID); err != nil || len(reveals) != 1 {
		t.Fatalf("reveals=%+v err=%v", reveals, err)
	}
}
