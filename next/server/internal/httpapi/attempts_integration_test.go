//go:build integration

package httpapi

import (
	"bytes"
	"context"
	"encoding/json"
	"io"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
	"quiz_master/next/server/internal/attempts"
	"quiz_master/next/server/internal/content"
	"quiz_master/next/server/internal/identity"
	"quiz_master/next/server/internal/migrate"
)

func TestRealBundleBearerEndToEnd(t *testing.T) {
	ctx := context.Background()
	pool, err := pgxpool.New(ctx, os.Getenv("QM_TEST_DATABASE_URL"))
	if err != nil {
		t.Fatal(err)
	}
	defer pool.Close()
	if err = migrate.Apply(ctx, pool, migrate.Migrations()); err != nil {
		t.Fatal(err)
	}
	now := func() time.Time { return time.Date(2026, 9, 20, 12, 0, 0, 0, time.UTC) }
	ident := identity.NewService(pool, now, identity.NewTokenSource(nil))
	p, token, err := ident.CreateGuest(ctx, "E2E owner")
	if err != nil {
		t.Fatal(err)
	}
	_, other, err := ident.CreateGuest(ctx, "E2E stranger")
	if err != nil {
		t.Fatal(err)
	}
	auth := func(ctx context.Context, raw string) (Principal, error) {
		p, e := ident.Authenticate(ctx, raw)
		return Principal{ID: p.ID, Kind: p.Kind}, e
	}
	newHandler := func() http.Handler {
		s, e := attempts.NewService(ctx, pool, "../../../content/home-alone-1-part-1/bundle.json", "../../../contracts/quiz-contract/v1/schemas", 30*time.Minute, attempts.Options{Now: now})
		if e != nil {
			t.Fatal(e)
		}
		return AttemptRoutes(s, auth)
	}
	server := httptest.NewServer(newHandler())
	defer server.Close()
	captures := []json.RawMessage{}
	validateDefinition := func(data []byte, name string) {
		schemaRaw, e := os.ReadFile("../../../contracts/quiz-contract/v1/schemas/attempts.schema.json")
		if e != nil {
			t.Fatal(e)
		}
		var schema map[string]any
		if e = json.Unmarshal(schemaRaw, &schema); e != nil {
			t.Fatal(e)
		}
		wrapper, _ := json.Marshal(map[string]any{"$schema": schema["$schema"], "$defs": schema["$defs"], "$ref": "#/$defs/" + name})
		path := filepath.Join(t.TempDir(), "consumer.json")
		if e = os.WriteFile(path, wrapper, 0600); e != nil {
			t.Fatal(e)
		}
		if e = content.ValidateSchema(data, path, "response"); e != nil {
			t.Fatal(e)
		}
	}
	call := func(method, path, credential string, body any, want int) []byte {
		var raw []byte
		switch v := body.(type) {
		case string:
			raw = []byte(v)
		default:
			raw, _ = json.Marshal(body)
		}
		req, e := http.NewRequest(method, server.URL+path, bytes.NewReader(raw))
		if e != nil {
			t.Fatal(e)
		}
		req.Header.Set("Content-Type", "application/json")
		if credential != "" {
			req.Header.Set("Authorization", "Bearer "+credential)
		}
		res, e := server.Client().Do(req)
		if e != nil {
			t.Fatal(e)
		}
		defer res.Body.Close()
		data, e := io.ReadAll(res.Body)
		if e != nil {
			t.Fatal(e)
		}
		if res.StatusCode != want {
			t.Fatalf("%s %s status %d want %d", method, path, res.StatusCode, want)
		}
		for _, marker := range []string{"private_grading", "grading", "correct_option_id", "correct_option_ids", "correct_answer", "accepted_variants", "explanation", "correctness", token, other} {
			if bytes.Contains(data, []byte(marker)) {
				t.Fatalf("private marker leaked: %s", strings.ReplaceAll(marker, token, "token"))
			}
		}
		if json.Valid(data) {
			captures = append(captures, append([]byte(nil), data...))
		}
		if path == "/v1/attempts" && want == 201 {
			start, e1 := time.Parse(time.RFC3339Nano, res.Header.Get("X-Attempt-Started-At"))
			deadline, e2 := time.Parse(time.RFC3339Nano, res.Header.Get("X-Attempt-Deadline-At"))
			if e1 != nil || e2 != nil || deadline.Sub(start) != 30*time.Minute {
				t.Fatal("server timing headers")
			}
		}
		return data
	}
	var catalog attempts.Catalog
	if err = json.Unmarshal(call("GET", "/v1/catalog", "", nil, 200), &catalog); err != nil {
		t.Fatal(err)
	}
	for _, q := range catalog.Quiz.Questions {
		raw, _ := json.Marshal(q)
		if err = content.ValidateSchema(raw, "../../../contracts/quiz-contract/v1/schemas/public-question.schema.json", "response"); err != nil {
			t.Fatal(err)
		}
	}
	call("POST", "/v1/attempts", "", `{}`, 401)
	call("POST", "/v1/attempts", token, `{"participant_id":"someone-else"}`, 400)
	call("POST", "/v1/attempts", token, `{"deadline_at":"2099-01-01T00:00:00Z"}`, 400)
	var a attempts.Attempt
	raw := call("POST", "/v1/attempts", token, `{}`, 201)
	if err = json.Unmarshal(raw, &a); err != nil {
		t.Fatal(err)
	}
	if err = content.ValidateSchema(raw, "../../../contracts/quiz-contract/v1/schemas/attempts.schema.json", "start"); err != nil {
		t.Fatal(err)
	}
	external, _ := attempts.ExternalParticipant(p.ID)
	if a.ParticipantID != external {
		t.Fatal("identity boundary")
	}
	// Independently map the source's nonzero index using the accepted manifest;
	// neither the scoring helper nor the bundle's private key computes expectation.
	sourceRaw, e := os.ReadFile("../../../../quizzes/Cinema/HomeAlone/home_alone_1_part_1.json")
	if e != nil {
		t.Fatal(e)
	}
	var source struct {
		Questions []struct {
			ID            string `json:"id"`
			CorrectAnswer int    `json:"correct_answer"`
		}
	}
	if e = json.Unmarshal(sourceRaw, &source); e != nil {
		t.Fatal(e)
	}
	manifestRaw, e := os.ReadFile("../../../content/home-alone-1-part-1/manifest.json")
	if e != nil {
		t.Fatal(e)
	}
	var manifest content.Manifest
	if e = json.Unmarshal(manifestRaw, &manifest); e != nil {
		t.Fatal(e)
	}
	if source.Questions[1].CorrectAnswer != 1 || manifest.Questions[1].SourceID != source.Questions[1].ID {
		t.Fatal("source nonzero fixture changed")
	}
	expectedOption := manifest.Questions[1].Options[source.Questions[1].CorrectAnswer].CanonicalID
	makeRequest := func(index int, option, key string) attempts.AnswerRequest {
		q := a.QuestionSnapshots[index]
		r := attempts.AnswerRequest{QuestionID: q.QuestionID, QuestionRevision: q.QuestionRevision, Answer: attempts.Answer{OptionID: &option}, IdempotencyKey: key}
		r.PayloadDigest, _ = attempts.PayloadDigest(a.AttemptID, a.ParticipantID, r)
		return r
	}
	answerPath := "/v1/attempts/" + a.AttemptID + "/answers"
	good := makeRequest(1, expectedOption, "correct")
	forged, _ := json.Marshal(good)
	for _, field := range []string{`"server_score":999`, `"correctness":true`, `"participant_id":"forged"`} {
		call("POST", answerPath, token, string(forged[:len(forged)-1])+","+field+"}", 400)
	}
	call("POST", answerPath, other, good, 404)
	receipt := call("POST", answerPath, token, good, 200)
	validateDefinition(receipt, "receipt")
	replay := call("POST", answerPath, token, good, 200)
	if !bytes.Equal(receipt, replay) {
		t.Fatal("HTTP replay receipt differs")
	}
	call("POST", answerPath, token, makeRequest(1, manifest.Questions[1].Options[0].CanonicalID, "correct"), 409)
	call("POST", answerPath, token, makeRequest(2, manifest.Questions[2].Options[0].CanonicalID, "wrong"), 200)
	finishPath := "/v1/attempts/" + a.AttemptID + "/finish"
	call("POST", finishPath, token, `{"server_score":999}`, 400)
	finished := call("POST", finishPath, token, `{}`, 200)
	validateDefinition(finished, "attemptFinish")
	var result attempts.Finish
	_ = json.Unmarshal(finished, &result)
	if result.ServerScore != 1 || len(result.History) != 2 {
		t.Fatal("independent expected score 1 from one correct nonzero and one incorrect source answer")
	}
	server.Close()
	server = httptest.NewServer(newHandler())
	defer server.Close()
	if after := call("GET", "/v1/history/"+a.AttemptID, token, nil, 200); !bytes.Equal(finished, after) {
		t.Fatal("reconstructed service lost history")
	}
	if after := call("POST", finishPath, token, `{}`, 200); !bytes.Equal(finished, after) {
		t.Fatal("reconstructed finish is not idempotent")
	}
	call("GET", "/v1/history/"+a.AttemptID, other, nil, 404)
	call("GET", "/v1/history/a-does-not-exist", other, nil, 404)
	if string(call("GET", "/v1/history", other, nil, 200)) != "[]\n" {
		t.Fatal("cross-owner list leaked")
	}
	call("GET", "/v1/history", token, nil, 200)
	// Independently inspect whole attempt/question/receipt/history rows; only the
	// controlled-bundle table is permitted to contain private grading markers.
	var rowsClean bool
	if err = pool.QueryRow(ctx, `select not exists(select 1 from (select row_to_json(a)::text as data from attempts a union all select row_to_json(q)::text from attempt_questions q union all select row_to_json(r)::text from attempt_answers r) x where data like '%'||$1||'%' or data like '%'||$2||'%' or data ~ '"(private_grading|correct_option_ids?|accepted_variants|correct_answer|explanation|grading)"')`, token, other).Scan(&rowsClean); err != nil || !rowsClean {
		t.Fatal("stored public boundary leak", err)
	}
	if output := os.Getenv("QM_P09_RESPONSE_CAPTURE"); output != "" {
		data, _ := json.MarshalIndent(captures, "", "  ")
		if err = os.WriteFile(output, data, 0600); err != nil {
			t.Fatal(err)
		}
	}
	t.Logf("real P08 bundle: 25 public questions; bearer sessions; %d response captures; independent expected score=1; database private-marker/token scan clean", len(captures))
}
