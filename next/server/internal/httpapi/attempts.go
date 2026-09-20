package httpapi

import (
	"bytes"
	"encoding/json"
	"errors"
	"io"
	"mime"
	"net/http"
	"strings"
	"time"
	"unicode/utf8"

	"quiz_master/next/server/internal/attempts"
)

func AttemptRoutes(s *attempts.Service, auth TokenAuthenticator) http.Handler {
	mux := http.NewServeMux()
	mux.HandleFunc("GET /v1/catalog", func(w http.ResponseWriter, r *http.Request) { writeAttemptJSON(w, http.StatusOK, s.Catalog()) })
	protected := func(pattern string, f http.HandlerFunc) { mux.Handle(pattern, Authenticate(auth, RequirePrincipal(f))) }
	protected("POST /v1/attempts", func(w http.ResponseWriter, r *http.Request) {
		var body struct{}
		if err := decodeAttemptJSON(w, r, &body); err != nil {
			writeAttemptError(w, attempts.ErrValidation)
			return
		}
		p, _ := PrincipalFromContext(r.Context())
		a, err := s.Start(r.Context(), p.ID)
		if err != nil {
			writeAttemptError(w, err)
			return
		}
		// P04's closed attempt DTO has no timing fields. Expose server timing as
		// response metadata without extending the accepted consumer object.
		w.Header().Set("X-Attempt-Started-At", a.StartedAt.Format(time.RFC3339Nano))
		w.Header().Set("X-Attempt-Deadline-At", a.DeadlineAt.Format(time.RFC3339Nano))
		writeAttemptJSON(w, http.StatusCreated, a)
	})
	protected("POST /v1/attempts/{attempt}/answers", func(w http.ResponseWriter, r *http.Request) {
		var req attempts.AnswerRequest
		if err := decodeAttemptJSON(w, r, &req); err != nil {
			writeAttemptError(w, attempts.ErrValidation)
			return
		}
		p, _ := PrincipalFromContext(r.Context())
		receipt, err := s.Submit(r.Context(), p.ID, r.PathValue("attempt"), req)
		if err != nil {
			writeAttemptError(w, err)
			return
		}
		writeAttemptJSON(w, http.StatusOK, receipt)
	})
	protected("POST /v1/attempts/{attempt}/finish", func(w http.ResponseWriter, r *http.Request) {
		var body struct{}
		if err := decodeAttemptJSON(w, r, &body); err != nil {
			writeAttemptError(w, attempts.ErrValidation)
			return
		}
		p, _ := PrincipalFromContext(r.Context())
		f, err := s.Finish(r.Context(), p.ID, r.PathValue("attempt"))
		if err != nil {
			writeAttemptError(w, err)
			return
		}
		writeAttemptJSON(w, http.StatusOK, f)
	})
	protected("GET /v1/history", func(w http.ResponseWriter, r *http.Request) {
		p, _ := PrincipalFromContext(r.Context())
		history, err := s.ListHistory(r.Context(), p.ID)
		if err != nil {
			writeAttemptError(w, err)
			return
		}
		writeAttemptJSON(w, http.StatusOK, history)
	})
	protected("GET /v1/history/{attempt}", func(w http.ResponseWriter, r *http.Request) {
		p, _ := PrincipalFromContext(r.Context())
		history, err := s.GetHistory(r.Context(), p.ID, r.PathValue("attempt"))
		if err != nil {
			writeAttemptError(w, err)
			return
		}
		writeAttemptJSON(w, http.StatusOK, history)
	})
	return mux
}
func writeAttemptJSON(w http.ResponseWriter, status int, v any) {
	w.Header().Set("Content-Type", "application/json")
	w.Header().Set("Cache-Control", "no-store")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(v)
}
func writeAttemptError(w http.ResponseWriter, err error) {
	code, status, retry := "validation_failed", http.StatusInternalServerError, true
	switch {
	case errors.Is(err, attempts.ErrForbidden):
		code, status, retry = "forbidden", http.StatusNotFound, false
	case errors.Is(err, attempts.ErrValidation):
		status, retry = http.StatusBadRequest, false
	case errors.Is(err, attempts.ErrRevision):
		code, status, retry = "stale_revision", http.StatusConflict, false
	case errors.Is(err, attempts.ErrDeadline):
		code, status, retry = "deadline_exceeded", http.StatusConflict, false
	case errors.Is(err, attempts.ErrConflict):
		code, status, retry = "idempotency_conflict", http.StatusConflict, false
	}
	writeAttemptJSON(w, status, struct {
		Code      string            `json:"code"`
		Message   string            `json:"message"`
		Retryable bool              `json:"retryable"`
		Details   map[string]string `json:"details"`
	}{code, "request could not be completed", retry, map[string]string{}})
}
func decodeAttemptJSON(w http.ResponseWriter, r *http.Request, target any) error {
	media, _, err := mime.ParseMediaType(r.Header.Get("Content-Type"))
	if err != nil || media != "application/json" {
		return attempts.ErrValidation
	}
	raw, err := io.ReadAll(http.MaxBytesReader(w, r.Body, 64<<10))
	if err != nil || !utf8.Valid(raw) {
		return attempts.ErrValidation
	}
	d := json.NewDecoder(bytes.NewReader(raw))
	d.UseNumber()
	if err = checkJSONValue(d, 0); err != nil {
		return err
	}
	if _, err = d.Token(); err != io.EOF {
		return attempts.ErrValidation
	}
	d = json.NewDecoder(bytes.NewReader(raw))
	d.DisallowUnknownFields()
	if err = d.Decode(target); err != nil {
		return attempts.ErrValidation
	}
	return nil
}

// Reject duplicate/case-aliased keys and nulls before decoding. Go's decoder
// otherwise silently accepts these ambiguous inputs, including nested answers.
func checkJSONValue(d *json.Decoder, depth int) error {
	if depth > 16 {
		return attempts.ErrValidation
	}
	token, err := d.Token()
	if err != nil || token == nil {
		return attempts.ErrValidation
	}
	delim, ok := token.(json.Delim)
	if !ok {
		if depth == 0 {
			return attempts.ErrValidation
		}
		return nil
	}
	switch delim {
	case '{':
		seen := map[string]bool{}
		for d.More() {
			key, err := d.Token()
			if err != nil {
				return attempts.ErrValidation
			}
			s, ok := key.(string)
			if !ok || seen[s] || s != strings.ToLower(s) {
				return attempts.ErrValidation
			}
			seen[s] = true
			if err = checkJSONValue(d, depth+1); err != nil {
				return err
			}
		}
		end, err := d.Token()
		if err != nil || end != json.Delim('}') {
			return attempts.ErrValidation
		}
	case '[':
		if depth == 0 {
			return attempts.ErrValidation
		}
		for d.More() {
			if err := checkJSONValue(d, depth+1); err != nil {
				return err
			}
		}
		end, err := d.Token()
		if err != nil || end != json.Delim(']') {
			return attempts.ErrValidation
		}
	default:
		return attempts.ErrValidation
	}
	return nil
}
