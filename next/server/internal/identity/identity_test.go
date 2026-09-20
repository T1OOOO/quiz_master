package identity

import (
	"bytes"
	"testing"
)

func TestTokenSourceProducesOpaque256BitTokensAndStableDigests(t *testing.T) {
	token, err := NewTokenSource(bytes.NewReader(bytes.Repeat([]byte{7}, 32))).New()
	if err != nil {
		t.Fatal(err)
	}
	if len(token) != 64 {
		t.Fatalf("token length = %d, want 64 hex chars", len(token))
	}
	if got, want := Digest(token), "1967c0fdaed0b8f2618d3b1f4a9f8541ed315505acc26f5a41f382da8bdd9954"; got != want {
		t.Fatalf("digest = %s, want %s", got, want)
	}
}

func TestTokenSourceRejectsShortRandomInput(t *testing.T) {
	if _, err := NewTokenSource(bytes.NewReader(make([]byte, 31))).New(); err == nil {
		t.Fatal("short random input was accepted")
	}
}
