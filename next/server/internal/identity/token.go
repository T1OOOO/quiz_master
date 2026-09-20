package identity

import (
	"crypto/rand"
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"io"
)

type TokenSource struct{ reader io.Reader }

func NewTokenSource(reader io.Reader) TokenSource {
	if reader == nil {
		reader = rand.Reader
	}
	return TokenSource{reader: reader}
}
func (s TokenSource) New() (string, error) {
	b := make([]byte, 32)
	if _, err := io.ReadFull(s.reader, b); err != nil {
		return "", fmt.Errorf("generate session token: %w", err)
	}
	return hex.EncodeToString(b), nil
}
func Digest(token string) string {
	sum := sha256.Sum256([]byte(token))
	return hex.EncodeToString(sum[:])
}
