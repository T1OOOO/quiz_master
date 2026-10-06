package httpapi

import (
	"bytes"
	"crypto/sha256"
	"crypto/subtle"
	"encoding/json"
	"errors"
	"io"
	"mime"
	"net/http"
	"net/url"
	"strconv"
	"strings"
	"unicode/utf8"

	"quiz_master/next/server/internal/reports"
)

type FeedbackConfig struct {
	Store      *reports.Store
	AdminToken string
}

func registerReportRoutes(mux *http.ServeMux, auth TokenAuthenticator, cfg FeedbackConfig) {
	mux.Handle("POST /v1/reports", http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Cache-Control", "no-store")
		if len(r.Header.Values("Authorization")) != 1 {
			WriteError(w, http.StatusUnauthorized, ErrUnauthorized)
			return
		}
		Authenticate(auth, http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			var input reports.Request
			if err := decodeReportJSON(w, r, &input, 8<<20); err != nil {
				writeReportError(w, err)
				return
			}
			p, _ := PrincipalFromContext(r.Context())
			receipt, created, err := cfg.Store.Create(r.Context(), p.ID, input)
			if err != nil {
				writeReportError(w, err)
				return
			}
			status := http.StatusOK
			if created {
				status = http.StatusCreated
			}
			writeAttemptJSON(w, status, receipt)
		})).ServeHTTP(w, r)
	}))
	admin := func(next http.HandlerFunc) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			w.Header().Set("Cache-Control", "private, no-store")
			if !utf8.ValidString(cfg.AdminToken) || utf8.RuneCountInString(cfg.AdminToken) < 32 {
				writeReportFailure(w, http.StatusServiceUnavailable, "feedback_admin_disabled", "feedback administration is disabled", false)
				return
			}
			parts := strings.Fields(r.Header.Get("Authorization"))
			if len(r.Header.Values("Authorization")) != 1 || len(parts) != 2 || parts[0] != "Bearer" {
				WriteError(w, http.StatusUnauthorized, ErrUnauthorized)
				return
			}
			expected, actual := sha256.Sum256([]byte(cfg.AdminToken)), sha256.Sum256([]byte(parts[1]))
			if subtle.ConstantTimeCompare(expected[:], actual[:]) != 1 {
				WriteError(w, http.StatusUnauthorized, ErrUnauthorized)
				return
			}
			next(w, r)
		})
	}
	mux.Handle("GET /v1/admin/reports", admin(func(w http.ResponseWriter, r *http.Request) {
		status, limit, offset, err := reportQuery(r)
		if err != nil {
			writeReportError(w, err)
			return
		}
		page, err := cfg.Store.List(r.Context(), status, limit, offset)
		if err != nil {
			writeReportError(w, err)
			return
		}
		writeAttemptJSON(w, http.StatusOK, page)
	}))
	mux.Handle("POST /v1/admin/reports/{id}/status", admin(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.RawQuery != "" {
			writeReportError(w, reports.ErrValidation)
			return
		}
		var input struct {
			Status string `json:"status"`
		}
		if err := decodeReportJSON(w, r, &input, 1024); err != nil {
			writeReportError(w, err)
			return
		}
		report, err := cfg.Store.SetStatus(r.Context(), r.PathValue("id"), input.Status)
		if err != nil {
			writeReportError(w, err)
			return
		}
		writeAttemptJSON(w, http.StatusOK, report)
	}))
	mux.Handle("GET /v1/admin/reports/{id}/screenshot", admin(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.RawQuery != "" {
			writeReportError(w, reports.ErrValidation)
			return
		}
		data, err := cfg.Store.Screenshot(r.Context(), r.PathValue("id"))
		if err != nil {
			writeReportError(w, err)
			return
		}
		w.Header().Set("Content-Type", "image/png")
		w.Header().Set("X-Content-Type-Options", "nosniff")
		_, _ = w.Write(data)
	}))
	mux.Handle("DELETE /v1/admin/reports/{id}", admin(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.RawQuery != "" {
			writeReportError(w, reports.ErrValidation)
			return
		}
		if err := cfg.Store.Delete(r.Context(), r.PathValue("id")); err != nil {
			writeReportError(w, err)
			return
		}
		w.WriteHeader(http.StatusNoContent)
	}))
}

func decodeReportJSON(w http.ResponseWriter, r *http.Request, target any, limit int64) error {
	media, _, err := mime.ParseMediaType(r.Header.Get("Content-Type"))
	if err != nil || media != "application/json" {
		return reports.ErrValidation
	}
	raw, err := io.ReadAll(http.MaxBytesReader(w, r.Body, limit))
	var sizeError *http.MaxBytesError
	if errors.As(err, &sizeError) {
		return reports.ErrTooLarge
	}
	if err != nil || !utf8.Valid(raw) {
		return reports.ErrValidation
	}
	d := json.NewDecoder(bytes.NewReader(raw))
	d.UseNumber()
	if err = checkJSONValue(d, 0); err != nil {
		return reports.ErrValidation
	}
	if _, err = d.Token(); err != io.EOF {
		return reports.ErrValidation
	}
	d = json.NewDecoder(bytes.NewReader(raw))
	d.DisallowUnknownFields()
	if err = d.Decode(target); err != nil {
		return reports.ErrValidation
	}
	return nil
}

func reportQuery(r *http.Request) (string, int, int, error) {
	query, err := url.ParseQuery(r.URL.RawQuery)
	if err != nil {
		return "", 0, 0, reports.ErrValidation
	}
	for key, values := range query {
		if (key != "status" && key != "limit" && key != "offset") || len(values) != 1 {
			return "", 0, 0, reports.ErrValidation
		}
	}
	status, limit, offset := "open", 50, 0
	if values, ok := query["status"]; ok {
		status = values[0]
	}
	if values, ok := query["limit"]; ok {
		limit, err = strconv.Atoi(values[0])
		if err != nil {
			return "", 0, 0, reports.ErrValidation
		}
	}
	if values, ok := query["offset"]; ok {
		offset, err = strconv.Atoi(values[0])
		if err != nil {
			return "", 0, 0, reports.ErrValidation
		}
	}
	if (!reports.ValidStatus(status) && status != "all") || limit < 1 || limit > 100 || offset < 0 || offset > 100000 {
		return "", 0, 0, reports.ErrValidation
	}
	return status, limit, offset, nil
}

func writeReportError(w http.ResponseWriter, err error) {
	switch {
	case errors.Is(err, reports.ErrValidation):
		writeReportFailure(w, 400, "invalid_feedback", "invalid feedback report", false)
	case errors.Is(err, reports.ErrTooLarge):
		writeReportFailure(w, 413, "feedback_too_large", "feedback report exceeds limit", false)
	case errors.Is(err, reports.ErrConflict):
		writeReportFailure(w, 409, "feedback_conflict", "feedback request id already used", false)
	case errors.Is(err, reports.ErrNotFound):
		writeReportFailure(w, 404, "feedback_not_found", "feedback report not found", false)
	default:
		writeReportFailure(w, 500, "feedback_unavailable", "feedback is temporarily unavailable", true)
	}
}

func writeReportFailure(w http.ResponseWriter, status int, code, message string, retryable bool) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(struct {
		Code      string            `json:"code"`
		Message   string            `json:"message"`
		Retryable bool              `json:"retryable"`
		Details   map[string]string `json:"details"`
	}{code, message, retryable, map[string]string{}})
}
