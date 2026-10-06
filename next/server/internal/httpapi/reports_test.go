package httpapi

import (
	"bytes"
	"context"
	"database/sql"
	"encoding/base64"
	"encoding/json"
	"image"
	"image/png"
	"net/http"
	"net/http/httptest"
	"path/filepath"
	"strings"
	"testing"

	_ "modernc.org/sqlite"
	"quiz_master/next/server/internal/identity"
	"quiz_master/next/server/internal/reports"
	localsqlite "quiz_master/next/server/internal/sqlite"
)

const validReportBody = `{"request_id":"frq_0123456789abcdef0123456789abcdef","type":"ui","item_ids":["screen:/library"],"comment":"Private feedback","context":{"route":"/library","viewport":{"width":390,"height":844,"dpr":2},"locale":"en","theme":"light","platform":"web","app_version":"test","timestamp":"2026-10-06T00:00:00Z"}}`
const feedbackAdminToken = "test-only-administrator-credential-0123456789"

func newFeedbackStore(t *testing.T) *reports.Store {
	t.Helper()
	db, err := sql.Open("sqlite", filepath.Join(t.TempDir(), "reports.db"))
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = db.Close() })
	if err = localsqlite.Apply(context.Background(), db); err != nil {
		t.Fatal(err)
	}
	if _, err = db.Exec(`INSERT INTO participants(id,kind,display_name,created_at,updated_at) VALUES('p_0123456789abcdef0123456789abcdef','guest','Guest','2026-10-06T00:00:00Z','2026-10-06T00:00:00Z')`); err != nil {
		t.Fatal(err)
	}
	return reports.NewStore(db)
}

func feedbackHandler(t *testing.T, adminToken string) http.Handler {
	t.Helper()
	return Routes(nil, func(_ context.Context, token string) (Principal, error) {
		if token != "guest-token" {
			return Principal{}, ErrUnauthorized
		}
		return Principal{ID: "p_0123456789abcdef0123456789abcdef", Kind: "guest"}, nil
	}, func(context.Context, string) (identity.GuestSession, error) { return identity.GuestSession{}, nil }, FeedbackConfig{Store: newFeedbackStore(t), AdminToken: adminToken})
}

func reportCall(h http.Handler, method, path, body, token string) *httptest.ResponseRecorder {
	r := httptest.NewRequest(method, path, strings.NewReader(body))
	r.Header.Set("Content-Type", "application/json")
	if token != "" {
		r.Header.Set("Authorization", "Bearer "+token)
	}
	w := httptest.NewRecorder()
	h.ServeHTTP(w, r)
	return w
}

func TestFeedbackRetriesRemainPrivateAndDetectConflicts(t *testing.T) {
	h := feedbackHandler(t, feedbackAdminToken)
	first := reportCall(h, "POST", "/v1/reports", validReportBody, "guest-token")
	if first.Code != 201 {
		t.Fatalf("first=%d %s", first.Code, first.Body.String())
	}
	if strings.Contains(first.Body.String(), "Private") || strings.Contains(first.Body.String(), "context") || first.Header().Get("Cache-Control") != "no-store" {
		t.Fatal("public response leaks or caches private report")
	}
	second := reportCall(h, "POST", "/v1/reports", validReportBody, "guest-token")
	if second.Code != 200 || second.Body.String() != first.Body.String() {
		t.Fatalf("retry=%d %s", second.Code, second.Body.String())
	}
	conflict := reportCall(h, "POST", "/v1/reports", strings.Replace(validReportBody, "Private feedback", "Changed feedback", 1), "guest-token")
	if conflict.Code != 409 || strings.Contains(conflict.Body.String(), "Changed") {
		t.Fatal("conflict was not safely rejected")
	}
	if reportCall(h, "POST", "/v1/reports", validReportBody, "").Code != 401 {
		t.Fatal("unauthenticated submission accepted")
	}
}

func TestFeedbackValidationRejectsUnsafeBodies(t *testing.T) {
	h := feedbackHandler(t, feedbackAdminToken)
	invalid := []string{
		`null`, `{}`, validReportBody + `{}`,
		strings.Replace(validReportBody, `"type":"ui"`, `"type":"ui","type":"idea"`, 1),
		strings.Replace(validReportBody, `"type":"ui"`, `"type":"other"`, 1),
		strings.Replace(validReportBody, `"type":"ui"`, `"type":"ui","participant_id":"other"`, 1),
		strings.Replace(validReportBody, `"viewport":{"width":390,"height":844,"dpr":2}`, `"viewport":null`, 1),
		strings.Replace(validReportBody, `"dpr":2`, `"dpr":2,"token":"secret"`, 1),
		strings.Replace(validReportBody, `"width":390`, `"width":0`, 1),
		strings.Replace(validReportBody, "Private feedback", "   ", 1),
		strings.Replace(validReportBody, "Private feedback", strings.Repeat("я", 5001), 1),
		strings.Replace(validReportBody, "/library", "/join/private-invite", -1),
		strings.Replace(validReportBody, "/library", "/library?token=secret", -1),
		strings.Replace(validReportBody, `"locale":"en"`, `"locale":null`, 1),
		strings.Replace(validReportBody, `"locale":"en"`, `"locale":"en","Locale":"ru"`, 1),
		strings.TrimSuffix(validReportBody, "}") + `,"screenshot":"bm90LWEtcG5n"}`,
	}
	for i, body := range invalid {
		w := reportCall(h, "POST", "/v1/reports", body, "guest-token")
		if w.Code != 400 {
			t.Fatalf("case%d=%d %s", i, w.Code, w.Body.String())
		}
		if strings.Contains(w.Body.String(), "secret") || strings.Contains(w.Body.String(), "Private") {
			t.Fatal("error echoes private payload")
		}
	}
	w := reportCall(h, "POST", "/v1/reports", strings.Repeat(" ", 8<<20)+validReportBody, "guest-token")
	if w.Code != 413 {
		t.Fatalf("oversize=%d", w.Code)
	}
}

func TestFeedbackAdministrationIsPrivateAndSupportsLifecycle(t *testing.T) {
	h := feedbackHandler(t, feedbackAdminToken)
	var pngBytes bytes.Buffer
	if err := png.Encode(&pngBytes, image.NewRGBA(image.Rect(0, 0, 2, 2))); err != nil {
		t.Fatal(err)
	}
	body := strings.TrimSuffix(validReportBody, "}") + `,"screenshot":"` + base64.StdEncoding.EncodeToString(pngBytes.Bytes()) + `"}`
	w := reportCall(h, "POST", "/v1/reports", body, "guest-token")
	var receipt reports.Receipt
	if w.Code != 201 || json.Unmarshal(w.Body.Bytes(), &receipt) != nil {
		t.Fatalf("creation=%d %s", w.Code, w.Body.String())
	}
	for _, token := range []string{"", "guest-token", "incorrect-administrator-credential"} {
		if reportCall(h, "GET", "/v1/admin/reports", "", token).Code != 401 {
			t.Fatal("admin endpoint accepted nonoperator credential")
		}
	}
	w = reportCall(h, "GET", "/v1/admin/reports", "", feedbackAdminToken)
	var page reports.Page
	if w.Code != 200 || json.Unmarshal(w.Body.Bytes(), &page) != nil || page.Total != 1 || !page.Reports[0].HasScreenshot || strings.Contains(w.Body.String(), base64.StdEncoding.EncodeToString(pngBytes.Bytes())) {
		t.Fatal("invalid private list or screenshot leak")
	}
	if !strings.Contains(w.Header().Get("Cache-Control"), "no-store") {
		t.Fatal("admin list caches private data")
	}
	imageResponse := reportCall(h, "GET", "/v1/admin/reports/"+receipt.ID+"/screenshot", "", feedbackAdminToken)
	if imageResponse.Code != 200 || !bytes.Equal(imageResponse.Body.Bytes(), pngBytes.Bytes()) || imageResponse.Header().Get("Content-Type") != "image/png" {
		t.Fatal("screenshot response differs")
	}
	for range 2 {
		if reportCall(h, "POST", "/v1/admin/reports/"+receipt.ID+"/status", `{"status":"resolved"}`, feedbackAdminToken).Code != 200 {
			t.Fatal("resolve/repeated resolve failed")
		}
	}
	w = reportCall(h, "GET", "/v1/admin/reports?status=open", "", feedbackAdminToken)
	if json.Unmarshal(w.Body.Bytes(), &page) != nil || page.Total != 0 || len(page.Reports) != 0 {
		t.Fatal("total must be filtered")
	}
	for _, query := range []string{"?limit=0", "?offset=-1", "?limit=1&limit=2", "?unknown=true", "?status=bad", "?offset=100001", "?limit=%zz"} {
		if reportCall(h, "GET", "/v1/admin/reports"+query, "", feedbackAdminToken).Code != 400 {
			t.Fatalf("query %s accepted", query)
		}
	}
	if reportCall(h, "DELETE", "/v1/admin/reports/"+receipt.ID, "", feedbackAdminToken).Code != 204 {
		t.Fatal("delete failed")
	}
	if reportCall(h, "DELETE", "/v1/admin/reports/"+receipt.ID, "", feedbackAdminToken).Code != 404 {
		t.Fatal("repeated delete should return404")
	}
	if reportCall(h, "GET", "/v1/admin/reports/"+receipt.ID+"/screenshot", "", feedbackAdminToken).Code != 404 {
		t.Fatal("deleted screenshot persists")
	}
	if reportCall(feedbackHandler(t, ""), "GET", "/v1/admin/reports", "", feedbackAdminToken).Code != 503 {
		t.Fatal("unconfigured admin must be disabled")
	}
}
