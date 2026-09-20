package httpapi

import (
	"context"
	"net/http"
	"time"

	"quiz_master/next/server/internal/attempts"
	"quiz_master/next/server/internal/identity"
)

type GuestCreator func(context.Context, string) (identity.GuestSession, error)

func IdentityRoutes(create GuestCreator) http.Handler {
	mux := http.NewServeMux()
	registerIdentityRoutes(mux, create)
	return mux
}

func registerIdentityRoutes(mux *http.ServeMux, create GuestCreator) {
	mux.HandleFunc("POST /v1/guests", func(w http.ResponseWriter, r *http.Request) {
		var body struct {
			DisplayName string `json:"display_name"`
		}
		if err := decodeAttemptJSON(w, r, &body); err != nil {
			writeAttemptError(w, attempts.ErrValidation)
			return
		}
		displayName, err := identity.CleanDisplayName(body.DisplayName)
		if err != nil {
			writeAttemptError(w, attempts.ErrValidation)
			return
		}
		session, err := create(r.Context(), displayName)
		if err != nil {
			writeAttemptError(w, err)
			return
		}
		participantID, err := attempts.ExternalParticipant(session.Principal.ID)
		if err != nil {
			writeAttemptError(w, err)
			return
		}
		writeAttemptJSON(w, http.StatusCreated, struct {
			ParticipantID string    `json:"participant_id"`
			Kind          string    `json:"kind"`
			DisplayName   string    `json:"display_name"`
			Token         string    `json:"token"`
			ExpiresAt     time.Time `json:"expires_at"`
		}{participantID, session.Principal.Kind, session.Principal.DisplayName, session.Token, session.ExpiresAt.UTC()})
	})
}
