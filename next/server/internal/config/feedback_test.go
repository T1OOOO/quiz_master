package config

import (
	"strings"
	"testing"
)

func TestFeedbackOperatorCredentialIsOptionalAndBounded(t *testing.T) {
	t.Setenv("QM_LISTEN_ADDR", "127.0.0.1:8088")
	t.Setenv("QM_DATABASE_URL", "sqlite:C:/tmp/quiz-master-feedback-test.db")
	for _, token := range []string{"", strings.Repeat("x", 32)} {
		t.Setenv("QM_FEEDBACK_ADMIN_TOKEN", token)
		cfg, err := FromEnv()
		if err != nil || cfg.FeedbackAdminToken != token {
			t.Fatal("valid operator configuration rejected")
		}
	}
	for _, token := range []string{"private-short-secret", strings.Repeat("x", 31), strings.Repeat("x", 4097), strings.Repeat("x", 32) + "\n"} {
		t.Setenv("QM_FEEDBACK_ADMIN_TOKEN", token)
		_, err := FromEnv()
		if err == nil || strings.Contains(err.Error(), token) {
			t.Fatal("invalid credential accepted or exposed in error")
		}
	}
}
