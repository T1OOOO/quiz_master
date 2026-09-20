package httpapi

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"strings"
)

var ErrUnauthorized = errors.New("request is not authorized")

type Principal struct{ ID, Kind string }
type principalKey struct{}

func WithPrincipal(ctx context.Context, p Principal) context.Context {
	return context.WithValue(ctx, principalKey{}, p)
}
func PrincipalFromContext(ctx context.Context) (Principal, bool) {
	p, ok := ctx.Value(principalKey{}).(Principal)
	return p, ok
}
func RequirePrincipal(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if _, ok := PrincipalFromContext(r.Context()); !ok {
			WriteError(w, http.StatusUnauthorized, ErrUnauthorized)
			return
		}
		next.ServeHTTP(w, r)
	})
}

type TokenAuthenticator func(context.Context, string) (Principal, error)

func Authenticate(auth TokenAuthenticator, next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		parts := strings.Fields(r.Header.Get("Authorization"))
		if len(parts) != 2 || parts[0] != "Bearer" {
			WriteError(w, http.StatusUnauthorized, ErrUnauthorized)
			return
		}
		p, err := auth(r.Context(), parts[1])
		if err != nil {
			WriteError(w, http.StatusUnauthorized, ErrUnauthorized)
			return
		}
		next.ServeHTTP(w, r.WithContext(WithPrincipal(r.Context(), p)))
	})
}
func WriteError(w http.ResponseWriter, status int, err error) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(struct {
		Code      string            `json:"code"`
		Message   string            `json:"message"`
		Retryable bool              `json:"retryable"`
		Details   map[string]string `json:"details"`
	}{"forbidden", "request is not authorized", false, map[string]string{}})
}
